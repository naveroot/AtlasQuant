export type AgentRole =
  | "Orchestrator"
  | "Cloud Agent"
  | "Spec Review"
  | "Grounding"
  | "Implement"
  | "Review"
  | "Blocked";

const STATE_KEY_TO_ROLE: Record<string, AgentRole> = {
  spec_review: "Spec Review",
  grounding: "Grounding",
  implement: "Implement",
  review: "Review",
  blocked: "Blocked",
};

/** Admin key for setup (states, one-time config). */
export function requirePlaneAdminKey(): string {
  const value = process.env.PLANE_API_KEY;
  if (!value) {
    throw new Error("PLANE_API_KEY is required for admin/setup operations");
  }
  return value;
}

/**
 * Agent key for pipeline writes (comments, state updates).
 * Falls back to PLANE_API_KEY for backward compatibility.
 */
export function resolvePlaneAgentKey(): string {
  const agentKey = process.env.PLANE_AGENT_API_KEY?.trim();
  if (agentKey) return agentKey;

  const fallback = process.env.PLANE_API_KEY?.trim();
  if (fallback) return fallback;

  throw new Error(
    "PLANE_AGENT_API_KEY or PLANE_API_KEY is required for pipeline operations",
  );
}

export function roleForStateKey(stateKey: string): AgentRole | undefined {
  return STATE_KEY_TO_ROLE[stateKey];
}

export function formatAgentComment(role: AgentRole, message: string): string {
  const escaped = message
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  return `<p><strong>[${role}]</strong> ${escaped}</p>`;
}
