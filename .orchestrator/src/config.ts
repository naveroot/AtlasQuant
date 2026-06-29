import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parse as parseYaml } from "yaml";

export interface OrchestratorConfig {
  plane: {
    base_url: string;
    workspace: string;
    project_id: string;
    agent_ready_label_id: string;
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

const __dirname = dirname(fileURLToPath(import.meta.url));
const CONFIG_PATH = resolve(__dirname, "..", "config.yml");

export function loadConfig(): OrchestratorConfig {
  if (!existsSync(CONFIG_PATH)) {
    throw new Error(
      `Missing ${CONFIG_PATH}. Copy config.example.yml → config.yml and fill in values.`,
    );
  }

  const raw = parseYaml(readFileSync(CONFIG_PATH, "utf8")) as OrchestratorConfig;

  return {
    plane: {
      base_url: process.env.PLANE_BASE_URL ?? raw.plane.base_url,
      workspace: process.env.PLANE_WORKSPACE ?? raw.plane.workspace,
      project_id: process.env.PLANE_PROJECT_ID ?? raw.plane.project_id,
      agent_ready_label_id:
        process.env.PLANE_AGENT_READY_LABEL_ID ?? raw.plane.agent_ready_label_id,
      poll_interval_seconds: raw.plane.poll_interval_seconds ?? 300,
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
