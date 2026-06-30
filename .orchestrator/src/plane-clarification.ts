function escapeHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Formats a structured Plane work item comment when an agent needs human input.
 * Matches the template in docs/agent-pipeline/agent-clarification.md.
 */
export function formatClarificationComment(
  role: string,
  questions: string[],
  assumed?: string,
): string {
  if (questions.length === 0) {
    throw new Error("At least one question is required");
  }

  const roleEscaped = escapeHtml(role.trim());
  const items = questions
    .map((q) => `<li>${escapeHtml(q.trim())}</li>`)
    .join("");

  let html = `<p><strong>[Needs Info] [${roleEscaped}]</strong></p>`;
  html += `<p>Blocked pending clarification:</p>`;
  html += `<ol>${items}</ol>`;

  if (assumed?.trim()) {
    html += `<p><em>Assumed if no reply:</em> ${escapeHtml(assumed.trim())}</p>`;
  }

  return html;
}

export const NEEDS_INFO_PROTOCOL = `
## Needs Info protocol (Plane task communication)

When brief, spec, plan, or codebase facts are **missing or ambiguous** — do **not** guess.

1. Post a structured clarification comment in the **Plane work item** (same issue):
   - Supercode: \`create_work_item_comment\` via Plane MCP, or
     \`bash .supercode/workflows/atlasquant/scripts/agent-clarification.sh <Role> <issue_id> "Q1" "Q2"\`
   - Cloud Agent: describe questions in your result; orchestrator posts on Blocked transition when applicable
2. Move work item to **Blocked** (MCP \`update_work_item\` or script above)
3. **Stop** current SDD stage until a human replies in Plane comments
4. After human reply: human moves task from Blocked → Agent Ready (or current stage); reload issue + comments before continuing

Comment format: \`[Needs Info] [Role]\`, numbered questions, optional «Assumed if no reply».
See \`docs/agent-pipeline/agent-clarification.md\`.
`.trim();
