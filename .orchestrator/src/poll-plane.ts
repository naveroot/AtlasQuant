import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { loadConfig, getStateId } from "./config.js";
import {
  formatAgentComment,
  resolvePlaneAgentKey,
} from "./plane-auth.js";
import {
  getWorkItemStateId,
  PlaneApiError,
  PlaneClient,
} from "./plane-client.js";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

interface FailedDispatchState {
  failed: string[];
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..", "..");

function loadFailedState(path: string): FailedDispatchState {
  if (!existsSync(path)) return { failed: [] };
  return JSON.parse(readFileSync(path, "utf8")) as FailedDispatchState;
}

function saveFailedState(path: string, state: FailedDispatchState): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(state, null, 2));
}

function startAgentForIssue(issueId: string): Promise<number> {
  return new Promise((resolveExit, reject) => {
    const child = spawn(
      "mise",
      ["exec", "--", "npm", "run", "agent", "--", `--issue=${issueId}`],
      {
        cwd: resolve(REPO_ROOT, ".orchestrator"),
        stdio: "inherit",
        env: process.env,
      },
    );
    child.on("error", reject);
    child.on("close", resolveExit);
  });
}

async function pollOnce(): Promise<void> {
  const config = loadConfig();
  const statePath = resolve(REPO_ROOT, config.state_file);
  const failedState = loadFailedState(statePath);

  const plane = new PlaneClient(
    config.plane.base_url,
    resolvePlaneAgentKey(),
    config.plane.workspace,
    config.plane.project_id,
  );

  const readyStateId = getStateId(config, "ready");
  const specReviewStateId = getStateId(config, "spec_review");
  const blockedStateId = getStateId(config, "blocked");
  const agentReadyLabelId = process.env.PLANE_AGENT_READY_LABEL_ID;

  const pipelineStateIds = new Set([
    specReviewStateId,
    getStateId(config, "grounding"),
    getStateId(config, "implement"),
    getStateId(config, "review"),
    blockedStateId,
    getStateId(config, "done"),
    getStateId(config, "cancelled"),
  ]);

  const items = await plane.listWorkItems();
  const readyByState = plane.filterByState(items, readyStateId);
  const ready = plane.filterDispatchReady(
    items,
    readyStateId,
    agentReadyLabelId,
    pipelineStateIds,
  );
  const readyByLabel = ready.filter(
    (item) => !readyByState.some((s) => s.id === item.id),
  );

  const pending = ready
    .filter((item) => !failedState.failed.includes(item.id))
    .sort((a, b) => a.sequence_id - b.sequence_id);

  console.log(
    `[${new Date().toISOString()}] Plane: ${items.length} issues, ` +
      `${ready.length} dispatch-ready (${readyByState.length} state, ${readyByLabel.length} label), ` +
      `${pending.length} pending`,
  );

  if (pending.length === 0) {
    console.log(
      `[${new Date().toISOString()}] No dispatch-ready issues ` +
        `(need state "Agent Ready" or label "agent-ready")`,
    );
    return;
  }

  const issue = pending[0];
  console.log(
    `[${new Date().toISOString()}] Claiming: ${issue.name} (${issue.id})`,
  );

  await plane.updateWorkItemState(issue.id, specReviewStateId);
  await plane.addComment(
    issue.id,
    formatAgentComment("Orchestrator", "Claimed issue → Spec Review"),
  );

  const exitCode = await startAgentForIssue(issue.id);

  if (exitCode === 0) {
    console.log(`[${new Date().toISOString()}] Agent finished for ${issue.id}`);
  } else {
    failedState.failed.push(issue.id);
    saveFailedState(statePath, failedState);

    const currentState = getWorkItemStateId(await plane.getWorkItem(issue.id));
    if (currentState !== blockedStateId) {
      await plane.updateWorkItemState(issue.id, blockedStateId);
    }
    await plane.addComment(
      issue.id,
      formatAgentComment(
        "Orchestrator",
        `Cloud agent failed (exit ${exitCode}). State → Blocked. Check orchestrator logs.`,
      ),
    );
  }
}

async function main(): Promise<void> {
  const config = loadConfig();
  const once = process.argv.includes("--once");

  const labelId = process.env.PLANE_AGENT_READY_LABEL_ID;
  console.log(`Plane poller started (interval: ${config.plane.poll_interval_seconds}s)`);
  console.log(`Trigger state: ready (${getStateId(config, "ready")})`);
  if (labelId) {
    console.log(`Label fallback: agent-ready (${labelId})`);
  }

  do {
    try {
      await pollOnce();
    } catch (err) {
      if (err instanceof PlaneApiError && err.isRateLimited) {
        const waitSec = err.retryAfterSeconds ?? 60;
        console.error(
          `Plane rate limit exceeded. Wait ~${waitSec}s before retry, or dispatch directly:\n` +
            `  npm run agent -- --issue=<work-item-uuid>`,
        );
        if (!once) {
          await new Promise((r) => setTimeout(r, waitSec * 1000));
        }
      } else {
        console.error("Poll error:", err);
      }
    }

    if (!once) {
      await new Promise((r) => setTimeout(r, config.plane.poll_interval_seconds * 1000));
    }
  } while (!once);
}

main();
