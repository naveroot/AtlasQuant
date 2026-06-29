import { Agent, CursorAgentError } from "@cursor/sdk";
import { getStateId, loadConfig, requireEnv } from "./config.js";
import {
  formatAgentComment,
  resolvePlaneAgentKey,
} from "./plane-auth.js";
import {
  getWorkItemStateId,
  PlaneClient,
} from "./plane-client.js";
import { buildAgentPrompt } from "./build-prompt.js";

async function main(): Promise<void> {
  const config = loadConfig();
  const apiKey = requireEnv("CURSOR_API_KEY");

  if (!config.github.repo_url) {
    throw new Error("github.repo_url is required in config.yml or GITHUB_REPO_URL");
  }

  const issueArg = process.argv.find((a) => a.startsWith("--issue="));
  const issueId = issueArg?.split("=")[1];

  let prompt: string;
  let planeIssueId: string | undefined;
  let plane: PlaneClient | undefined;

  if (issueId) {
    plane = new PlaneClient(
      config.plane.base_url,
      resolvePlaneAgentKey(),
      config.plane.workspace,
      config.plane.project_id,
    );
    const issue = await plane.getWorkItem(issueId);
    prompt = buildAgentPrompt(issue);
    planeIssueId = issue.id;

    const currentStateId = getWorkItemStateId(issue);
    const readyStateId = getStateId(config, "ready");
    const specReviewStateId = getStateId(config, "spec_review");

    if (currentStateId === readyStateId) {
      await plane.updateWorkItemState(issue.id, specReviewStateId);
      await plane.addComment(
        issue.id,
        formatAgentComment("Cloud Agent", "Started → Spec Review"),
      );
    }

    console.log(`Starting cloud agent for: ${issue.name}`);
  } else if (process.argv.includes("--pilot")) {
    prompt = buildAgentPrompt({
      id: "pilot",
      name: "User model + SessionsController + has_secure_password",
      sequence_id: 1,
      project_identifier: "ATLASQUANT",
      description_stripped:
        "Implement User auth MVP: User model with has_secure_password, SessionsController, RegistrationsController, basic ERB views. RSpec tests (or Minitest if RSpec migration pending). Follow SDD gates in prompt.",
      description_html: "",
      labels: [],
      state: "todo",
    });
    console.log("Starting cloud agent for pilot task (no Plane issue)");
  } else {
    console.error("Usage:");
    console.error("  npm run agent -- --issue=<plane-work-item-uuid>");
    console.error("  npm run agent -- --pilot");
    process.exit(1);
  }

  let agentError = false;

  try {
    await using agent = await Agent.create({
      apiKey,
      model: { id: config.cursor.model },
      cloud: {
        repos: [
          {
            url: config.github.repo_url,
            startingRef: config.cursor.default_branch,
          },
        ],
        autoCreatePR: config.cursor.auto_create_pr,
        skipReviewerRequest: config.cursor.skip_reviewer_request,
      },
    });

    console.log("Agent ID:", agent.agentId);

    const run = await agent.send(prompt);
    console.log("Run ID:", run.id);

    const result = await run.wait();

    console.log("Status:", result.status);
    if (result.result) console.log("\nResult:\n", result.result);
    if (result.git?.branches?.length) {
      for (const b of result.git.branches) {
        if (b.prUrl) console.log("PR:", b.prUrl);
        if (b.branch) console.log("Branch:", b.branch);
      }
    }

    if (result.status === "error") {
      agentError = true;
    }

    if (planeIssueId && plane) {
      const prLink = result.git?.branches?.find((b) => b.prUrl)?.prUrl;

      if (agentError) {
        await plane.updateWorkItemState(
          planeIssueId,
          getStateId(config, "blocked"),
        );
        await plane.addComment(
          planeIssueId,
          formatAgentComment(
            "Cloud Agent",
            `Error. Agent: ${agent.agentId}`,
          ),
        );
      } else {
        await plane.updateWorkItemState(
          planeIssueId,
          getStateId(config, "review"),
        );
        const finishMessage = prLink
          ? `Finished → Review. Agent: ${agent.agentId}. PR: ${prLink}`
          : `Finished → Review. Agent: ${agent.agentId}`;
        await plane.addComment(
          planeIssueId,
          formatAgentComment("Cloud Agent", finishMessage),
        );
      }
    }

    if (agentError) {
      process.exit(2);
    }
  } catch (err) {
    if (planeIssueId && plane) {
      await plane.updateWorkItemState(
        planeIssueId,
        getStateId(config, "blocked"),
      );
      await plane.addComment(
        planeIssueId,
        formatAgentComment("Cloud Agent", "Startup/runtime failure"),
      );
    }

    if (err instanceof CursorAgentError) {
      console.error("Startup failed:", err.message, `(retryable=${err.isRetryable})`);
      process.exit(1);
    }
    throw err;
  }
}

main();
