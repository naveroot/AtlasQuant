# AtlasQuant — Memory Bank

Двухслойный контекст для агентов (по модели AI SWE / SDD).

## Слой 1 — устойчивый контекст проекта

| Документ | Назначение |
|----------|------------|
| [AGENTS.md](../AGENTS.md) | Продукт, стек, MVP scope, security policy |
| [agent-pipeline/README.md](agent-pipeline/README.md) | Конвейер Plane → Supercode → CI → PR |
| [specs/README.md](specs/README.md) | Формат спецификаций и TAUS quality gate |

## Слой 2 — контекст изменения (per feature)

| Артефакт | Путь | Статус |
|----------|------|--------|
| Brief | Plane issue / prompt | — |
| Spec Pack | `docs/specs/<id>.md` | `draft` → `active` |
| Implementation Plan | `docs/plans/<id>.md` | `draft` → `active` |
| Run state (Ralph Loop) | `.agent-run/` (gitignored) | per session |

**Правило:** агент на шаге Implement получает только артефакты со статусом `active`.

## Quality Gates

```
[Gate 1] Spec TAUS review     → docs/specs/*.md status: active
[Gate 2] Grounding            → plan сверен с кодовой базой
[Gate 3] CI (bin/ci)          → lint, security, tests
[Gate 4] Spec-conformance     → diff покрывает все AC
[Gate 5] Human PR review      → GitHub
```

## Adapt routing (куда возвращать при сбое)

| Сбой | Вернуть на |
|------|------------|
| Тесты, lint, brakeman | Implement (+ CI loop) |
| План не сходится с кодом | Grounding → Architect |
| Решение не закрывает AC | Spec Review → Architect |
| Сырой/неясный brief | Plane / уточнение задачи |
