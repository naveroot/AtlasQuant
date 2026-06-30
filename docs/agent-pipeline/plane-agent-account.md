# Plane agent service account

Отдельная учётная запись Plane, чтобы комментарии SDD-агентов отображались в UI **не от имени оператора**, а от сервисного пользователя. Роль SDD (`Architect`, `Implement`, …) по-прежнему указывается **в тексте комментария** — см. [agent-clarification.md](agent-clarification.md).

## Dual-key policy

| Переменная | Назначение | Операции |
|------------|------------|----------|
| `PLANE_API_KEY` | Admin / orchestrator | list issues, PATCH state, CI sync, setup |
| `PLANE_AGENT_API_KEY` | Agent voice | POST comments (`addComment`, MCP `create_work_item_comment`) |

Если `PLANE_AGENT_API_KEY` не задан, все операции используют `PLANE_API_KEY` (обратная совместимость).

## 1. Создать пользователя в Plane UI

1. Откройте `https://plane.alfapulse.ru` (или ваш self-hosted URL).
2. **Settings → Workspace → Members → Invite** (или God Mode → Users, для CE).
3. Email: `atlasquant-agent@your-domain` (любой рабочий адрес; пароль храните в password manager).
4. **Display name:** `AtlasQuant Agent` (именно это имя видно в комментариях).
5. Роль в workspace: **Member** (достаточно для комментариев и смены state в проекте).
6. Добавьте пользователя в проект **ATLASQUANT** с ролью **Member**.

## 2. Выпустить API key

1. Войдите под учётной записью **AtlasQuant Agent**.
2. **Profile → API Tokens** → Create token.
3. Скопируйте ключ (показывается один раз).

## 3. Заполнить env

```bash
# .orchestrator/.env
PLANE_AGENT_API_KEY=plane_api_...

# .supercode/workflows/atlasquant/.env
PLANE_AGENT_API_KEY=plane_api_...
```

`PLANE_API_KEY` остаётся ключом **вашего** admin-аккаунта (orchestrator, poller, GitHub Actions sync).

## 4. Проверка

```bash
bash .supercode/workflows/atlasquant/scripts/verify-plane-agent.sh
bash .supercode/workflows/atlasquant/scripts/verify-plane-agent.sh --expect "AtlasQuant Agent"
```

Ожидаемый stdout: `display_name=AtlasQuant Agent` (или ваш display name).

## Где используется agent-ключ

| Компонент | Agent key |
|-----------|-----------|
| `poll-plane.ts` / `start-agent.ts` | только `addComment` |
| `agent-clarification.sh` | POST comment |
| `update-plane-state.sh` | POST comment (PATCH state — admin) |
| `plane-mcp-server.sh` | все MCP-вызовы (Supercode пишет комментарии от agent) |

## Роли в комментариях

Plane показывает **display name** автора. Роль SDD — в HTML:

```html
<p><strong>[Needs Info] [Architect]</strong></p>
```

Gate-комментарии orchestrator используют эмодзи-префикс (`🤖`) без отдельного Plane-пользователя на роль.

## Troubleshooting

| Симптом | Решение |
|---------|---------|
| `verify-plane-agent.sh` exit 1, 401 | Проверьте ключ, пересоздайте token |
| `--expect` mismatch | Обновите display name в Plane или флаг `--expect` |
| Agent не может PATCH state | Добавьте Member в project; для clarification state меняет admin-ключ |
| MCP комментарии от human | Задайте `PLANE_AGENT_API_KEY`, перезагрузите Cursor |

## Related

- [Agent Clarification Protocol](agent-clarification.md)
- [Agent SWE Pipeline README](README.md)
