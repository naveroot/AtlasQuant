import type { PlaneWorkItem } from "./plane-client.js";
import { NEEDS_INFO_PROTOCOL } from "./plane-clarification.js";

const AGENTS_RULES = `
Rules (from AGENTS.md):
- Domain logic in app/services/, not fat controllers
- Each new model/service needs RSpec tests (target stack; Minitest until migration done)
- UI: ERB + Tailwind, Stimulus only for interactivity
- MVP scope only — no OAuth, Redis, real-time exchange APIs
- Run bin/ci before considering work complete
- Security: has_secure_password, strong params, no secrets in code
`.trim();

const SDD_GATES = `
## SDD Quality Gates (AI SWE methodology)

| Gate | Check | Exit signal |
|------|-------|-------------|
| 1 | TAUS spec review | spec status: active |
| 2 | Grounding (plan vs codebase) | GATE_2: PASS |
| 3 | CI (bin/ci) | Exit code: 0 |
| 4 | Spec conformance (AC vs diff) | GATE_4: PASS |
| 5 | Human PR review | GitHub |

**No evidence → not done.** Each AC needs file/test proof in PR body.

**Adapt routing on failure:**
- CI/lint/tests fail → fix implementation
- Plan conflicts with codebase → revise plan (draft) + re-ground
- AC not met → continue implement
- Ambiguous spec → revise spec (draft) + re-run TAUS review
- Missing/ambiguous brief or facts → Needs Info in Plane (see below), do not guess

${NEEDS_INFO_PROTOCOL}
`.trim();

export function buildAgentPrompt(issue: PlaneWorkItem): string {
  const description =
    issue.description_stripped?.trim() ||
    stripHtml(issue.description_html) ||
    "(no description)";

  const identifier = issue.project_identifier
    ? `${issue.project_identifier}-${issue.sequence_id}`
    : `#${issue.sequence_id}`;

  const slug = identifier.replace(/[^a-zA-Z0-9-]/g, "-");

  return `
# AtlasQuant SWE Task — ${identifier}: ${issue.name}

## Description
${description}

## Workflow (Spec-Driven Development)

### Phase 1 — Spec (no code)
1. Read AGENTS.md and docs/index.md
2. Create **Spec Pack** Plane Page \`docs/specs/${slug}.md\` (parent: specs; template: Page \`docs/specs/_template.md\`)
   - TAUS: Testable AC, Ambiguous-free, Uniform states, Scoped to one feature
3. Create **Implementation Plan** Plane Page \`docs/plans/${slug}.md\` (parent: plans; status: draft)
4. Self-review spec against TAUS → set both to **status: active** only when TAUS passes

### Phase 2 — Grounding
5. Verify plan against current codebase (files exist, MVP scope, feasibility)
6. Init Ralph Loop: copy templates from docs/agent-pipeline/templates/agent-run/ to .agent-run/

### Phase 3 — Implement (one checkbox per iteration)
7. Implement only with active spec/plan; minimal diff
8. Update .agent-run/plan.md and active-context.md each iteration
9. Write tests for new models/services/controllers

### Phase 4 — Verify
10. Ensure \`bin/ci\` passes (rubocop, brakeman, bundler-audit, tests)
11. Spec conformance: every AC in spec has evidence in diff/tests
12. Open PR with: title (conventional commit), AC checklist, evidence table, commands run

${SDD_GATES}

${AGENTS_RULES}

Plane issue ID: ${issue.id}
`.trim();
}

function stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}
