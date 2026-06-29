# Agent SWE Pipeline — AtlasQuant

Конвейер агентской разработки по модели **Spec-Driven Development** (курс [AI SWE](https://ai-swe-1.thinknetica.com)):

**Plane → Brief → Spec (TAUS) → Grounding → Implement → CI → Conformance → PR**

## Quality Gates

```
Brief (Plane issue)
    ↓
[Gate 1] TAUS Spec Review     docs/specs/*.md → status: active
    ↓
[Gate 2] Grounding            plan vs codebase
    ↓
[Gate 3] CI                   bin/ci (lint, security, tests)
    ↓
[Gate 4] Spec Conformance     AC vs diff evidence
    ↓
[Gate 5] Human PR review      GitHub
```

Memory Bank: [docs/index.md](../index.md)

## Быстрый старт (локально, Supercode)

### 1. Установить Supercode

Расширение: [supercode.sh/install](https://supercode.sh/en/install)

### 2. Pilot без Plane

1. Откройте проект AtlasQuant в Cursor
2. Supercode menu → buttons → **SWE Pipeline (Manual)**
3. Введите задачу, например:
   ```
   feat: User model + SessionsController + has_secure_password
   ```
4. Pipeline: Architect → TAUS → Grounding → Implement → CI → Conformance → Review

### 3. Pilot с Plane

1. Скопируйте `.supercode/workflows/atlasquant/.env.example` → `.env`
2. Заполните `PLANE_API_KEY`, `PLANE_WORKSPACE`, `PLANE_PROJECT_ID`, `PLANE_ISSUE_IDENTIFIER`
3. Supercode menu → **SWE Pipeline (Plane)**

## Cloud Agent (удалённое исполнение)

### 1. Настройка orchestrator

```bash
cd .orchestrator
cp config.example.yml config.yml
cp .env.example .env
# Заполните CURSOR_API_KEY, PLANE_API_KEY, github.repo_url

npm install
```

### 2. Pilot cloud agent (без Plane)

```bash
export CURSOR_API_KEY=cursor_...
npm run agent -- --pilot
```

Cloud agent получает SDD workflow с quality gates в промпте.

### 3. Cloud agent для задачи Plane

```bash
npm run agent -- --issue=<work-item-uuid>
```

### 4. Poller (Plane label `agent-ready`)

```bash
npm start              # каждые 5 мин
npm start -- --once    # один проход
```

## Структура

```
docs/
├── index.md                          # Memory Bank index
├── specs/                            # Spec Pack (TAUS)
│   ├── README.md
│   └── _template.md
├── plans/                            # Implementation plans
└── agent-pipeline/
    ├── README.md
    └── templates/agent-run/          # Ralph Loop templates

.supercode/workflows/atlasquant/
├── swe-pipeline.yml                  # полный SDD конвейер
├── swe-architect.yml                 # spec + plan (draft)
├── swe-spec-review.yml               # Gate 1: TAUS
├── swe-grounding.yml                 # Gate 2
├── swe-implement.yml                 # Gate 3: code + CI loop
├── swe-spec-conformance.yml          # Gate 4
└── scripts/
    ├── fetch-plane-issue.sh
    ├── init-agent-run.sh             # Ralph Loop init
    └── run-ci-gate.sh

.agent-run/                           # gitignored, per-session state
.orchestrator/                        # Cursor Cloud Agent + Plane poller
```

## Workflow stages

| Этап | Supercode | Cloud Agent |
|------|-----------|-------------|
| Intake | `fetch-plane-issue.sh` + `init-agent-run.sh` | `buildAgentPrompt()` |
| Architect | SWE Architect | Phase 1 in prompt |
| Gate 1 TAUS | SWE Spec Review Loop | Self TAUS in prompt |
| Gate 2 Grounding | SWE Grounding | Phase 2 in prompt |
| Gate 3 Implement | SWE Implement + CI loop | Phase 3–4 in prompt |
| Gate 4 Conformance | SWE Spec Conformance Loop | AC evidence in prompt |
| Gate 5 Review | Final Review step | PR with evidence table |

## Ralph Loop (длинные задачи)

При fetch из Plane или Architect автоматически создаётся `.agent-run/`:

| Файл | Назначение |
|------|------------|
| `PROMPT.md` | Launcher instructions |
| `plan.md` | Checkbox progress |
| `active-context.md` | Current focus |
| `verification-loop.md` | CI failures, checks |
| `session-handoff.md` | Resume point |

## Adapt routing

| Сбой | Вернуть на |
|------|------------|
| CI red | Implement |
| Plan vs code conflict | Architect + Grounding |
| AC not met | Implement |
| Spec ambiguous | Architect + Spec Review |

## Следующие шаги

- [ ] Push на GitHub → `GITHUB_REPO_URL` в config.yml
- [ ] Pilot: **SWE Pipeline (Manual)** на User auth
- [ ] Cloud smoke: `npm run agent -- --pilot`
- [ ] Запустить poller как systemd/cron service
