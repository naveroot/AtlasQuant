import assert from "node:assert/strict";
import test from "node:test";
import { resolvePlaneAgentApiKey } from "./config.js";

test("resolvePlaneAgentApiKey prefers PLANE_AGENT_API_KEY", () => {
  process.env.PLANE_API_KEY = "admin-key";
  process.env.PLANE_AGENT_API_KEY = "agent-key";

  assert.equal(resolvePlaneAgentApiKey(), "agent-key");

  delete process.env.PLANE_AGENT_API_KEY;
  assert.equal(resolvePlaneAgentApiKey(), "admin-key");

  delete process.env.PLANE_API_KEY;
});

test("resolvePlaneAgentApiKey throws when no keys set", () => {
  delete process.env.PLANE_API_KEY;
  delete process.env.PLANE_AGENT_API_KEY;

  assert.throws(
    () => resolvePlaneAgentApiKey(),
    /PLANE_API_KEY is required/,
  );
});
