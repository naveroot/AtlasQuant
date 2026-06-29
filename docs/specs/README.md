# Spec Pack — AtlasQuant

> **Источник истины:** Plane Page с `external_id` `docs/specs/<slug>.md` (см. [../plane-pages/README.md](../plane-pages/README.md)).

Спецификация задачи перед реализацией. Основано на **TAUS** (курс AI SWE).

## Статусы

| Статус | Значение |
|--------|----------|
| `draft` | Черновик — Architect создал, Gate 1 ещё не пройден |
| `active` | TAUS review пройден — можно Implement |

## TAUS checklist (Gate 1)

```
[ ] T — Testable: checkbox AC с конкретным поведением (success + error)
[ ] A — Ambiguous-free: нет «удобно», «быстро», «и т.д.»
[ ] U — Uniform: все состояния и edge cases описаны
[ ] S — Scoped: одна фича, < 1500 слов
```

## Именование (external_id)

```
docs/specs/<plane-id-or-slug>.md    # Spec Pack
docs/plans/<plane-id-or-slug>.md    # Implementation Plan
```

Шаблон: Plane Page `docs/specs/_template.md`

## Workflow

1. **Architect** создаёт spec + plan Pages со статусом `draft`
2. **Spec Review** (Supercode: SWE Spec Review) — TAUS gate → `active` или список правок
3. **Grounding** — сверка plan с репозиторием
4. **Implement** — только при `active` spec/plan
