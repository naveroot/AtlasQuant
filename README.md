# AtlasQuant

Веб-приложение для отслеживания **валютных фьючерсов MOEX** и аналитики **базиса, контанго и стоимости удержания** (implied cost of carry).

AtlasQuant помогает пользователям отслеживать динамику инструментов в персональном списке, получать аналитику по текущим рыночным условиям на FORTS и оценивать отклонение цены фьючерса от спота — базис и annualized implied yield до экспирации.

Стратегическое решение по ядру продукта: [docs/decisions/001-product-core-moex-basis.md](docs/decisions/001-product-core-moex-basis.md).

## Технологический стек

| Слой | Технология |
|------|------------|
| Backend | Ruby 3.2.11, Rails 8.1 |
| База данных | PostgreSQL 16 |
| Кэш | Solid Cache (PostgreSQL) |
| Фоновые задачи | Solid Queue (PostgreSQL) |
| WebSocket | Solid Cable (PostgreSQL) |
| Frontend | Tailwind CSS, Hotwire (Turbo + Stimulus), importmap |
| Деплой | Kamal, Docker |
| Среда разработки | [Mise](https://mise.jdx.dev/) |

Redis **не используется** — Rails 8 Solid-адаптеры хранят кэш, очереди и Action Cable в PostgreSQL.

## Требования

- [Mise](https://mise.jdx.dev/) (управляет Ruby и PostgreSQL из `mise.toml`)
- Git

## Быстрый старт

```bash
mise install
mise exec -- bin/setup
mise exec -- bin/dev
```

Приложение будет доступно на [http://localhost:3000](http://localhost:3000).

`bin/setup` устанавливает gem-зависимости, подготавливает базу данных и по умолчанию запускает dev-сервер. Чтобы пропустить autostart сервера:

```bash
mise exec -- bin/setup --skip-server
```

## Команды

| Команда | Назначение |
|---------|------------|
| `bin/dev` | Dev-сервер + Tailwind CSS watch (Foreman, `Procfile.dev`) |
| `bin/setup` | Установка зависимостей и подготовка БД |
| `bin/rails db:prepare` | Создание и миграция базы данных |
| `bin/rails test` | Запуск тестов (Minitest) |
| `bin/ci` | Полный локальный CI: setup → rubocop → security scans → тесты |
| `bin/jobs` | Запуск воркеров Solid Queue |

## Тестирование

```bash
mise exec -- bin/rails test
```

Локальный CI-прогон (рекомендуется перед PR):

```bash
mise exec -- bin/ci
```

Целевой стек MVP — RSpec + SimpleCov; подробности в [AGENTS.md](AGENTS.md).

## Безопасность и CI

В проекте настроены:

- `bin/rubocop` — стиль кода
- `bin/bundler-audit` — аудит CVE в gem-зависимостях
- `bin/importmap audit` — аудит JS-зависимостей
- `bin/brakeman` — статический анализ уязвимостей Rails

GitHub Actions: `.github/workflows/ci.yml`.

## Деплой

Контейнеризация через `Dockerfile`, оркестрация — [Kamal](https://kamal-deploy.org/) (`config/deploy.yml`).

## Документация

| Документ | Назначение |
|----------|------------|
| [AGENTS.md](AGENTS.md) | MVP scope, архитектура, security policy, правила для агентов |
| [docs/decisions/001-product-core-moex-basis.md](docs/decisions/001-product-core-moex-basis.md) | ADR: ядро продукта — MOEX базис |
| [docs/index.md](docs/index.md) | Memory Bank и SDD quality gates |
| [docs/agent-pipeline/README.md](docs/agent-pipeline/README.md) | Конвейер Plane → Supercode → CI → PR |

## Лицензия

См. репозиторий проекта.
