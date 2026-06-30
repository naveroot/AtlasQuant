import { loadConfig, requireEnv, resolvePlaneAgentApiKey } from "./config.js";
import { PlaneClient } from "./plane-client.js";

export interface PlaneClients {
  admin: PlaneClient;
  agent: PlaneClient;
}

/** Admin key for state/list ops; agent key for comments (may be the same client). */
export function createPlaneClients(): PlaneClients {
  const config = loadConfig();
  const adminKey = requireEnv("PLANE_API_KEY");
  const agentKey = resolvePlaneAgentApiKey();

  const base = {
    baseUrl: config.plane.base_url,
    workspace: config.plane.workspace,
    projectId: config.plane.project_id,
  };

  const admin = new PlaneClient(
    base.baseUrl,
    adminKey,
    base.workspace,
    base.projectId,
  );

  const agent =
    agentKey === adminKey
      ? admin
      : new PlaneClient(
          base.baseUrl,
          agentKey,
          base.workspace,
          base.projectId,
        );

  return { admin, agent };
}
