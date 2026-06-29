# Spec Pack — AtlasQuant

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

## Именование

```
docs/specs/<plane-id-or-slug>.md    # Spec Pack
docs/plans/<plane-id-or-slug>.md    # Implementation Plan
```

Шаблон: [_template.md](_template.md)

## Workflow

1. **Architect** создаёт spec + plan со статусом `draft`
2. **Spec Review** (Supercode: SWE Spec Review) — TAUS gate → `active` или список правок
3. **Grounding** — сверка plan с репозиторием
4. **Implement** — только при `active` spec/plan
