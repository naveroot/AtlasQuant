import { loadConfig, requireEnv, type PlaneStateKey } from "./config.js";
import {
  PlaneClient,
  type PlaneState,
  type PlaneStateGroup,
} from "./plane-client.js";

interface PipelineStateDef {
  key: PlaneStateKey;
  name: string;
  group: PlaneStateGroup;
  color: string;
  reuseExistingName?: string;
}

const PIPELINE_STATES: PipelineStateDef[] = [
  {
    key: "ready",
    name: "Agent Ready",
    group: "unstarted",
    color: "#3B82F6",
  },
  {
    key: "spec_review",
    name: "Spec Review",
    group: "started",
    color: "#8B5CF6",
  },
  {
    key: "grounding",
    name: "Grounding",
    group: "started",
    color: "#06B6D4",
  },
  {
    key: "implement",
    name: "Implement",
    group: "started",
    color: "#F59E0B",
  },
  {
    key: "review",
    name: "Review",
    group: "started",
    color: "#10B981",
  },
  {
    key: "blocked",
    name: "Blocked",
    group: "backlog",
    color: "#EF4444",
  },
  {
    key: "done",
    name: "Done",
    group: "completed",
    color: "#22C55E",
    reuseExistingName: "Done",
  },
  {
    key: "cancelled",
    name: "Cancelled",
    group: "cancelled",
    color: "#94A3B8",
    reuseExistingName: "Cancelled",
  },
];

async function main(): Promise<void> {
  const config = loadConfig({ requireStates: false }).plane;
  const plane = new PlaneClient(
    config.base_url,
    requireEnv("PLANE_API_KEY"),
    config.workspace,
    config.project_id,
  );

  const existing = await plane.listStates();
  const resolved: Record<PlaneStateKey, string> = {} as Record<
    PlaneStateKey,
    string
  >;

  console.log("Plane pipeline states setup\n");

  for (const def of PIPELINE_STATES) {
    let state: PlaneState | undefined;

    if (def.reuseExistingName) {
      state = plane.findStateByName(existing, def.reuseExistingName);
      if (state) {
        console.log(`✓ Reuse ${def.key}: ${state.name} (${state.id})`);
        resolved[def.key] = state.id;
        continue;
      }
    }

    state = plane.findStateByName(existing, def.name);
    if (state) {
      console.log(`✓ Exists ${def.key}: ${state.name} (${state.id})`);
      resolved[def.key] = state.id;
      continue;
    }

    state = await plane.createState(def.name, def.group, def.color);
    console.log(`+ Created ${def.key}: ${state.name} (${state.id})`);
    resolved[def.key] = state.id;
    existing.push(state);
    await new Promise((r) => setTimeout(r, 1500));
  }

  console.log("\n--- config.yml snippet ---\n");
  console.log("plane:");
  console.log(`  base_url: ${config.base_url}`);
  console.log(`  workspace: ${config.workspace}`);
  console.log(`  project_id: ${config.project_id}`);
  console.log("  states:");
  for (const def of PIPELINE_STATES) {
    console.log(`    ${def.key}: "${resolved[def.key]}"`);
  }

  console.log("\n--- .env snippet ---\n");
  for (const def of PIPELINE_STATES) {
    const envKey = `PLANE_STATE_${def.key.toUpperCase()}`;
    console.log(`${envKey}=${resolved[def.key]}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
