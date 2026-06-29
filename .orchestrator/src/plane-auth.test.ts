import assert from "node:assert/strict";
import { describe, it, afterEach } from "node:test";
import {
  formatAgentComment,
  resolvePlaneAgentKey,
  roleForStateKey,
} from "./plane-auth.js";

describe("plane-auth", () => {
  const originalAgentKey = process.env.PLANE_AGENT_API_KEY;
  const originalApiKey = process.env.PLANE_API_KEY;

  afterEach(() => {
    if (originalAgentKey === undefined) {
      delete process.env.PLANE_AGENT_API_KEY;
    } else {
      process.env.PLANE_AGENT_API_KEY = originalAgentKey;
    }
    if (originalApiKey === undefined) {
      delete process.env.PLANE_API_KEY;
    } else {
      process.env.PLANE_API_KEY = originalApiKey;
    }
  });

  it("prefers PLANE_AGENT_API_KEY over PLANE_API_KEY", () => {
    process.env.PLANE_AGENT_API_KEY = "agent-key";
    process.env.PLANE_API_KEY = "admin-key";
    assert.equal(resolvePlaneAgentKey(), "agent-key");
  });

  it("falls back to PLANE_API_KEY when agent key missing", () => {
    delete process.env.PLANE_AGENT_API_KEY;
    process.env.PLANE_API_KEY = "admin-key";
    assert.equal(resolvePlaneAgentKey(), "admin-key");
  });

  it("throws when no keys configured", () => {
    delete process.env.PLANE_AGENT_API_KEY;
    delete process.env.PLANE_API_KEY;
    assert.throws(() => resolvePlaneAgentKey(), /PLANE_AGENT_API_KEY/);
  });

  it("formats comment with role prefix", () => {
    assert.equal(
      formatAgentComment("Orchestrator", "Claimed issue → Spec Review"),
      "<p><strong>[Orchestrator]</strong> Claimed issue → Spec Review</p>",
    );
  });

  it("escapes HTML in comment message", () => {
    assert.equal(
      formatAgentComment("Cloud Agent", "PR: <script>alert(1)</script>"),
      "<p><strong>[Cloud Agent]</strong> PR: &lt;script&gt;alert(1)&lt;/script&gt;</p>",
    );
  });

  it("maps state keys to roles", () => {
    assert.equal(roleForStateKey("spec_review"), "Spec Review");
    assert.equal(roleForStateKey("unknown"), undefined);
  });
});
