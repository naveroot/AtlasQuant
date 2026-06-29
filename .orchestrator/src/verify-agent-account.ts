import { loadConfig } from "./config.js";
import { resolvePlaneAgentKey } from "./plane-auth.js";
import { PlaneClient } from "./plane-client.js";

async function main(): Promise<void> {
  let apiKey: string;
  try {
    apiKey = resolvePlaneAgentKey();
  } catch (err) {
    console.error(
      err instanceof Error ? err.message : "Missing PLANE_AGENT_API_KEY",
    );
    process.exit(1);
  }

  const config = loadConfig({ requireStates: false }).plane;
  const plane = new PlaneClient(
    config.base_url,
    apiKey,
    config.workspace,
    config.project_id,
  );

  const user = await plane.getCurrentUser();
  const displayName =
    user.display_name?.trim() ||
    [user.first_name, user.last_name].filter(Boolean).join(" ").trim() ||
    user.email;

  console.log("Plane agent account verified");
  console.log(`  display_name: ${displayName}`);
  console.log(`  email: ${user.email}`);
  console.log(`  user_id: ${user.id}`);

  if (process.env.PLANE_AGENT_API_KEY?.trim()) {
    console.log("  key: PLANE_AGENT_API_KEY");
  } else {
    console.warn(
      "  warning: using PLANE_API_KEY fallback — set PLANE_AGENT_API_KEY for agent identity",
    );
  }
}

main().catch((err) => {
  console.error("verify:agent failed:", err instanceof Error ? err.message : err);
  process.exit(1);
});
