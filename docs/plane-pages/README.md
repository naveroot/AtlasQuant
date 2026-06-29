# Plane Pages — Memory Bank (AtlasQuant)

Документы Memory Bank перенесены из локального `docs/` в **Plane Pages** проекта ATLASQUANT.

## Источник истины

| Было (локально) | Стало (Plane Pages) |
|-----------------|---------------------|
| `docs/index.md` | Page `docs/index.md` |
| `docs/specs/*.md` | Pages под `specs/` |
| `docs/plans/*.md` | Pages под `plans/` |
| `docs/agent-pipeline/**` | Pages под `agent-pipeline/` |

Маппинг `external_id → page_id`: [manifest.yml](manifest.yml)

## CLI

```bash
# Первичный перенос (уже выполнен) + обновление manifest
bash .supercode/workflows/atlasquant/scripts/migrate-docs-to-plane-pages.sh --write-manifest

# Синхронизация Pages → локальный кэш для gate-скриптов
bash .supercode/workflows/atlasquant/scripts/plane-pages.sh pull

# Чтение страницы
bash .supercode/workflows/atlasquant/scripts/plane-pages.sh get docs/specs/-2.md
```

Plane CE v1.3.x: Pages API доступен через SSH + Django ORM (`PLANE_SSH_HOST`, по умолчанию VPS с Plane).

## Spec / Plan для задачи

| Slug | Spec external_id | Plan external_id |
|------|------------------|------------------|
| ATLASQUANT-2 | `docs/specs/-2.md` | `docs/plans/-2.md` |
| ATLASQUANT-1 | — | `docs/plans/#1.md` |

Новые задачи: `docs/specs/<slug>.md` и `docs/plans/<slug>.md` (slug = `ATLASQUANT-N` → `-N` или `#N` по конвенции).
