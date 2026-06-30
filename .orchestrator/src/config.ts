import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

export type PlaneStateKey =
  | "ready"
  | "spec_review"
  | "grounding"
  | "implement"
  | "review"
  | "done"
  | "blocked"
  | "cancelled";

export type PlaneStatesConfig = Record<PlaneStateKey, string>;

export interface OrchestratorConfig {
  plane: {
    base_url: string;
    workspace: string;
    project_id: string;
    states: PlaneStatesConfig;
    poll_interval_seconds: number;
  };
  cursor: {
    model: string;
    default_branch: string;
    auto_create_pr: boolean;
    skip_reviewer_request: boolean;
  };
  github: {
    repo_url: string;
  };
  state_file: string;
}

const PLANE_STATE_KEYS: PlaneStateKey[] = [
  "ready",
  "spec_review",
  "grounding",
  "implement",
  "review",
  "done",
  "blocked",
  "cancelled",
];

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONFIG_PATH = resolve(__dirname, "..", "config.yml");

function envStateKey(key: PlaneStateKey): string {
  return `PLANE_STATE_${key.toUpperCase()}`;
}

function loadPlaneStates(raw: Partial<PlaneStatesConfig>): PlaneStatesConfig {
  const states = {} as PlaneStatesConfig;

  for (const key of PLANE_STATE_KEYS) {
    const envValue = process.env[envStateKey(key)];
    const yamlValue = raw[key];
    const value = envValue ?? yamlValue;

    if (!value) {
      throw new Error(
        `Missing plane.states.${key} in config.yml or ${envStateKey(key)} env var. ` +
          `Run: npm run setup:states`,
      );
    }

    states[key] = value;
  }

  return states;
}

export function loadConfig(options?: { requireStates?: boolean }): OrchestratorConfig {
  const requireStates = options?.requireStates ?? true;

  if (!existsSync(CONFIG_PATH)) {
    throw new Error(
      `Missing ${CONFIG_PATH}. Copy config.example.yml → config.yml and fill in values.`,
    );
  }

  const raw = parseYaml(readFileSync(CONFIG_PATH, "utf8")) as OrchestratorConfig;

  const planeBase = {
    base_url: process.env.PLANE_BASE_URL ?? raw.plane.base_url,
    workspace: process.env.PLANE_WORKSPACE ?? raw.plane.workspace,
    project_id: process.env.PLANE_PROJECT_ID ?? raw.plane.project_id,
    poll_interval_seconds: raw.plane.poll_interval_seconds ?? 300,
  };

  return {
    plane: {
      ...planeBase,
      states: requireStates
        ? loadPlaneStates(raw.plane.states ?? {})
        : (raw.plane.states as PlaneStatesConfig),
    },
    cursor: raw.cursor,
    github: {
      repo_url: process.env.GITHUB_REPO_URL ?? raw.github.repo_url,
    },
    state_file: raw.state_file,
  };
}

export function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

/** Agent comments use PLANE_AGENT_API_KEY when set; otherwise same as admin key. */
export function resolvePlaneAgentApiKey(): string {
  return process.env.PLANE_AGENT_API_KEY?.trim() || requireEnv("PLANE_API_KEY");
}

export function getStateId(
  config: OrchestratorConfig,
  key: PlaneStateKey,
): string {
  return config.plane.states[key];
}
