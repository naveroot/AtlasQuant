# Plane agent account — учётная запись для SWE pipeline

Отдельный пользователь Plane, от имени которого orchestrator и Supercode scripts публикуют комментарии и обновляют состояния задач. Администраторский `PLANE_API_KEY` остаётся для одноразовой настройки (например `npm run setup:states`).

## Зачем

Без отдельной учётной записи все автоматические комментарии в Plane отображаются от имени владельца admin API-ключа. С `PLANE_AGENT_API_KEY` в UI видно, что действие выполнил агент (display name «Atlas SWE Agent»), а роль указывается в тексте комментария: `[Orchestrator]`, `[Cloud Agent]`, `[Spec Review]` и т.д.

## Шаг 1 — создать пользователя в Plane

1. Войдите в Plane как **администратор** workspace `atlasquant`.
2. **Settings → Members → Invite member** (или включите signup, если CE позволяет).
3. Email агента, например: `agent@alfapulse.ru` (или отдельный ящик команды).
4. Роль в workspace: **Member** (достаточно для комментариев и смены state в проекте).
5. Добавьте пользователя в проект **AtlasQuant** с ролью **Member** или выше.

## Шаг 2 — профиль агента

1. Войдите в Plane **под учётной записью агента** (или попросите агента сделать это).
2. **Profile → Display name:** `Atlas SWE Agent`
3. (Опционально) загрузите аватар для быстрой визуальной идентификации в activity feed.

## Шаг 3 — API-токен агента

1. Под пользователем агента: **Settings → API Tokens → Generate New Token**
2. Имя токена: `AtlasQuant SWE Pipeline`
3. Скопируйте токен сразу — повторно он не показывается.
4. Сохраните в секреты (не в git):

```bash
# .orchestrator/.env
PLANE_AGENT_API_KEY=plane_api_...

# .supercode/workflows/atlasquant/.env (для Supercode pipeline)
PLANE_AGENT_API_KEY=plane_api_...
```

`PLANE_API_KEY` оставьте ключом **администратора** для `setup:states` и других admin-операций.

## Шаг 4 — проверка

```bash
cd .orchestrator
cp .env.example .env   # если ещё не настроено
# заполните PLANE_AGENT_API_KEY, PLANE_WORKSPACE, PLANE_PROJECT_ID, PLANE_BASE_URL

npm install
npm run verify:agent
```

Ожидаемый вывод:

```
Plane agent account verified
  display_name: Atlas SWE Agent
  email: agent@alfapulse.ru
  user_id: ...
  key: PLANE_AGENT_API_KEY
```

Exit code `0` — ключ валиден. Exit code `1` — ключ отсутствует или неверный.

## Роли в комментариях

| Источник | Роль в комментарии |
|----------|-------------------|
| Plane poller (`poll-plane.ts`) | `[Orchestrator]` |
| Cloud agent (`start-agent.ts`) | `[Cloud Agent]` |
| `update-plane-state.sh spec_review` | `[Spec Review]` |
| `update-plane-state.sh grounding` | `[Grounding]` |
| `update-plane-state.sh implement` | `[Implement]` |
| `update-plane-state.sh review` | `[Review]` |
| `update-plane-state.sh blocked` | `[Blocked]` |

Пример комментария в Plane:

> **[Cloud Agent]** Finished → Review. Agent: bc-.... PR: https://github.com/...

Автор комментария в UI — **Atlas SWE Agent** (display name пользователя, владельца API-токена).

## Обратная совместимость

Если `PLANE_AGENT_API_KEY` не задан, pipeline использует `PLANE_API_KEY`. `verify:agent` в этом случае выведет предупреждение о fallback.

## GitHub Secrets (cloud agent / CI)

| Secret | Назначение |
|--------|------------|
| `PLANE_API_KEY` | Admin key (setup, опционально) |
| `PLANE_AGENT_API_KEY` | Agent key для pipeline writes |

Остальные переменные (`PLANE_BASE_URL`, `PLANE_WORKSPACE`, `PLANE_PROJECT_ID`, `PLANE_STATE_*`) без изменений — см. [README.md](README.md).
