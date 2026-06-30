import assert from "node:assert/strict";
import test from "node:test";
import { formatClarificationComment } from "./plane-clarification.js";

test("formatClarificationComment includes role and numbered questions", () => {
  const html = formatClarificationComment("Architect", [
    "Which auth scope?",
    "Include admin UI?",
  ]);

  assert.match(html, /\[Needs Info\] \[Architect\]/);
  assert.match(html, /<ol><li>Which auth scope\?<\/li><li>Include admin UI\?<\/li><\/ol>/);
  assert.match(html, /Blocked pending clarification/);
  assert.doesNotMatch(html, /Assumed if no reply/);
});

test("formatClarificationComment includes optional assumed block", () => {
  const html = formatClarificationComment(
    "Grounding",
    ["Is Instrument model required?"],
    "Proceed without Instrument model",
  );

  assert.match(html, /Assumed if no reply/);
  assert.match(html, /Proceed without Instrument model/);
});

test("formatClarificationComment escapes HTML in questions", () => {
  const html = formatClarificationComment("Implement", [
    'Use <script>alert("x")</script>?',
  ]);

  assert.match(html, /Use &lt;script&gt;alert\(&quot;x&quot;\)&lt;\/script&gt;\?/);
  assert.doesNotMatch(html, /<script>/);
});

test("formatClarificationComment rejects empty questions", () => {
  assert.throws(
    () => formatClarificationComment("Architect", []),
    /At least one question/,
  );
});
