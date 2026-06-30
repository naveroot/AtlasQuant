## Summary

<!-- Кратко: что и зачем -->

## Plane

<!-- Required: identifier for CI validation and auto-sync to Done after merge. -->
Plane: ATLASQUANT-

## Spec

- Spec: `docs/specs/…`
- Plan: `docs/plans/…`

## Acceptance Criteria (evidence required)

<!-- Каждый AC: [x] + file/test proof. No evidence → not done. -->

| AC | Done | Evidence |
|----|------|----------|
| | [ ] | |

## Quality Gates

- [ ] Gate 1 TAUS — spec status: active
- [ ] Gate 2 Grounding — plan verified vs codebase
- [ ] Gate 3 CI — `bin/ci` passes locally
- [ ] Gate 4 Spec conformance — all AC covered

## Test plan

```bash
bin/ci
# or: bundle exec rspec
```

## Out of scope check

- [ ] No MVP out-of-scope features added (see AGENTS.md)
