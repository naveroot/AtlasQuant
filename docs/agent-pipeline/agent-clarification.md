# Agent Clarification Protocol (Needs Info)

When SDD agents lack information or encounter ambiguity, they **must ask in the Plane work item** — not guess, not only write to `.agent-run/`.

## When to ask vs continue

| Situation | Action |
|-----------|--------|
| Brief missing acceptance criteria or domain terms | **Ask** in Plane |
| Spec AC ambiguous («удобно», «и т.д.») | **Ask** or return to Spec Review |
| Plan references files/models that do not exist and are not in scope to create | **Ask** |
| Security/auth decision not covered by AGENTS.md | **Ask** |
| Implement detail inferable from active spec + codebase | **Continue** |
| TAUS/gate failure with concrete fix list | **Revise** spec/plan (Adapt routing), no ask |

## Comment format

HTML comment on the work item:

```html
<p><strong>[Needs Info] [Role]</strong></p>
<p>Blocked pending clarification:</p>
<ol>
  <li>Specific question 1?</li>
  <li>Specific question 2?</li>
</ol>
<p><em>Assumed if no reply:</em> Default the agent will take if human stays silent (optional).</p>
```

**Role** examples: `Architect`, `Spec Review`, `Grounding`, `Implement`, `Cloud Agent`.

## Workflow

1. Agent identifies missing/ambiguous information.
2. Agent posts comment (see tools below).
3. Agent moves work item to **Blocked**.
4. Agent **stops** — no production code, no guessing.
5. Human replies in the **same Plane work item** thread.
6. Human moves task from **Blocked** → **Agent Ready** (or the appropriate SDD stage).
7. Agent reloads issue + comments before resuming.

## Tools

### Supercode (Plane MCP — preferred)

Use context from:

```bash
bash .supercode/workflows/atlasquant/scripts/plane-mcp-context.sh clarify Architect "Q1?" "Q2?"
```

Then:

1. `create_work_item_comment` with generated HTML
2. `update_work_item` → `state_id` = blocked

### Bash script (headless / Cloud Agent local)

```bash
bash .supercode/workflows/atlasquant/scripts/agent-clarification.sh \
  Architect \
  <work-item-uuid> \
  --assumed "Proceed with Minitest until RSpec migration" \
  "Should AC-6 use RSpec or Minitest?" \
  "Is admin-only CRUD in scope?"
```

Uses `PLANE_AGENT_API_KEY` if set, otherwise `PLANE_API_KEY`.

Exit codes: `0` success, `1` missing env / API error / no questions.

### Cloud Agent

Prompt in `.orchestrator/src/build-prompt.ts` includes the same protocol. When blocked on missing info, list numbered questions in the agent result; human posts to Plane and re-triggers agent.

## Environment

| Variable | Purpose |
|----------|---------|
| `PLANE_AGENT_API_KEY` | Preferred key for agent comments (optional) |
| `PLANE_API_KEY` | Fallback |
| `PLANE_STATE_BLOCKED` | Blocked state UUID |
| `PLANE_ISSUE_ID` | Default issue when UUID omitted in script |

## Related

- [Agent SWE Pipeline README](README.md) — Adapt routing, Blocked state
- [docs/index.md](../index.md) — «Сырой/неясный brief → Plane / уточнение задачи»
