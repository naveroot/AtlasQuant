# AtlasQuant — Memory Bank

> **Источник истины:** Plane Pages проекта ATLASQUANT ([plane-pages/README.md](plane-pages/README.md)).  
> Локальные файлы ниже — архивные снимки на момент миграции.

Двухслойный контекст для агентов (по модели AI SWE / SDD).

## Слой 1 — устойчивый контекст проекта

| Документ | Назначение |
|----------|------------|
| [AGENTS.md](../AGENTS.md) | Продукт, стек, MVP scope, security policy |
| [decisions/001-product-core-moex-basis.md](decisions/001-product-core-moex-basis.md) | ADR: ядро продукта — MOEX базис |
| [agent-pipeline/README.md](agent-pipeline/README.md) | Конвейер Plane → Supercode → CI → PR |
| [plane-pages/README.md](plane-pages/README.md) | Memory Bank в Plane Pages + manifest |

## Слой 2 — контекст изменения (per feature)

| Артефакт | Путь | Статус |
|----------|------|--------|
| Brief | Plane issue / prompt | Plane workflow state |
| Spec Pack | Plane Page `docs/specs/<id>.md` | `draft` → `active` |
| Implementation Plan | Plane Page `docs/plans/<id>.md` | `draft` → `active` |
| Run state (Ralph Loop) | `.agent-run/` (gitignored) | per session |

**Правило:** агент на шаге Implement получает только артефакты со статусом `active` и при Plane state **Implement** или позже.

## Plane workflow states

| Plane state | SDD gate |
|-------------|----------|
| Agent Ready | Триггер pipeline |
| Spec Review | Architect + Gate 1 |
| Grounding | Gate 2 |
| Implement | Gate 3 |
| Review | Gate 4–5 |
| Blocked | Сбой gate / agent |
| Done | PR merged (вручную) |

Подробности: [agent-pipeline/README.md](agent-pipeline/README.md)

## Quality Gates

```
[Gate 1] Spec TAUS review     → Plane Pages spec/plan status: active
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
