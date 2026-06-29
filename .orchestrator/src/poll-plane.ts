import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { loadConfig, requireEnv } from "./config.js";
import { PlaneClient } from "./plane-client.js";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

interface ProcessedState {
  processed: string[];
}

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, "..", "..");

function loadState(path: string): ProcessedState {
  if (!existsSync(path)) return { processed: [] };
  return JSON.parse(readFileSync(path, "utf8")) as ProcessedState;
}

function saveState(path: string, state: ProcessedState): void {
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
  const state = loadState(statePath);

  const plane = new PlaneClient(
    config.plane.base_url,
    requireEnv("PLANE_API_KEY"),
    config.plane.workspace,
    config.plane.project_id,
  );

  const items = await plane.listWorkItems();
  const ready = plane.filterAgentReady(items, config.plane.agent_ready_label_id);

  const pending = ready.filter((item) => !state.processed.includes(item.id));

  console.log(
    `[${new Date().toISOString()}] Plane: ${items.length} issues, ${ready.length} agent-ready, ${pending.length} pending`,
  );

  if (pending.length === 0) {
    console.log(`[${new Date().toISOString()}] No new agent-ready issues`);
    return;
  }

  const issue = pending[0];
  console.log(`[${new Date().toISOString()}] Processing: ${issue.name} (${issue.id})`);

  const exitCode = await startAgentForIssue(issue.id);

  if (exitCode === 0) {
    state.processed.push(issue.id);
    saveState(statePath, state);
    await plane.addComment(
      issue.id,
      `<p>🤖 Orchestrator dispatched cloud agent (exit 0)</p>`,
    );
  } else {
    await plane.addComment(
      issue.id,
      `<p>⚠️ Cloud agent failed (exit ${exitCode}). Check orchestrator logs.</p>`,
    );
  }
}

async function main(): Promise<void> {
  const config = loadConfig();
  const once = process.argv.includes("--once");

  console.log(`Plane poller started (interval: ${config.plane.poll_interval_seconds}s)`);

  do {
    try {
      await pollOnce();
    } catch (err) {
      console.error("Poll error:", err);
    }

    if (!once) {
      await new Promise((r) => setTimeout(r, config.plane.poll_interval_seconds * 1000));
    }
  } while (!once);
}

main();
