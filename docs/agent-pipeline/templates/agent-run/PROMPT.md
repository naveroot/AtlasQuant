# Agent Run — Ralph Loop Launcher

Постоянная инструкция для повторных итераций (паттерн Ralph Loop, AI SWE).

## Читать при каждом запуске

1. `AGENTS.md` — устойчивый контекст проекта
2. `docs/specs/<task>.md` — только если status: **active**
3. `docs/plans/<task>.md` — только если status: **active**
4. `.agent-run/plan.md` — прогресс чекбоксов
5. `.agent-run/active-context.md` — текущий фокус
6. `.agent-run/verification-loop.md` — открытые проверки

## Правила итерации

- Один checkbox за итерацию
- После каждого шага: обновить `plan.md` и `active-context.md`
- Запустить `bin/ci` перед завершением итерации
- **Нет evidence → не done** (diff + test output + AC checkbox)

## Exit criteria (остановка цикла)

- Все AC в spec отмечены выполненными
- `bin/ci` → Exit code: 0
- Spec-conformance review пройден
- PR summary готов

## При сбое (Adapt routing)

| Симптом | Действие |
|---------|----------|
| CI red | Fix → CI loop (не менять spec) |
| Plan vs codebase conflict | Обновить plan, status → draft, Grounding |
| AC не закрыты | Вернуться к Implement |
| Spec ambiguous | status → draft, Spec Review |
