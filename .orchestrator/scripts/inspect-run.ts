import { Agent } from "@cursor/sdk";
import { requireEnv } from "../src/config.js";

async function main(): Promise<void> {
  const agentId = process.argv[2];
  const runId = process.argv[3];
  if (!agentId) {
    console.error("Usage: tsx scripts/inspect-run.ts <agent-id> [run-id]");
    process.exit(1);
  }

  await using agent = await Agent.resume(agentId, {
    apiKey: requireEnv("CURSOR_API_KEY"),
  });

  const runs = await Agent.listRuns(agentId, { apiKey: requireEnv("CURSOR_API_KEY") });
  console.log("runs:", runs.items?.map((r) => ({ id: r.id, status: r.status, result: r.result?.slice(0, 200) })));

  const targetRunId = runId ?? runs.items?.[0]?.id;
  if (!targetRunId) {
    console.error("No runs found");
    process.exit(1);
  }

  const run = await Agent.getRun(targetRunId, { apiKey: requireEnv("CURSOR_API_KEY") });
  console.log("\nrun:", targetRunId);
  console.log("status:", run.status);
  console.log("result:", run.result ?? "(none)");
  console.log("durationMs:", run.durationMs);
  console.log("git:", JSON.stringify(run.git, null, 2));

  if (run.supports("conversation")) {
    const turns = await run.conversation();
    console.log("\n--- conversation ---");
    for (const turn of turns) {
      console.log(JSON.stringify(turn, null, 2));
    }
  } else {
    console.log("\nconversation unsupported:", run.unsupportedReason("conversation"));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
