# ADR-001: Ядро продукта — MOEX базис и стоимость удержания

**Status:** accepted  
**Date:** 2026-06-30  
**Plane:** ac8858bc-3403-4a0f-bf26-716bd704804e

## Контекст

AtlasQuant изначально позиционировался как сервис расчёта **funding rate** для **crypto-style perpetual-контрактов**. Фактическая интеграция (#4) работает с **MOEX FORTS** — срочными валютными фьючерсами (`Si`, `Eu`, `Cn`, `ED`) и квази-perpetual контрактами MOEX (`USDRUBF`, `EURRUBF`, `CNYRUBF`). На MOEX нет механизма funding rate как на crypto-биржах: у dated-фьючерсов ценность определяется **базисом** относительно спота и **стоимостью удержания** до экспирации; у MOEX-perpetual — собственная модель своп-цены, но не crypto funding.

Без выбора ядра заблокированы: `BasisCalculator`, метрики базиса, дашборд.

## Рассмотренные варианты

### Вариант (a): MOEX базис / контанго и стоимость удержания

| Аспект | Оценка |
|--------|--------|
| **Источник данных** | MOEX ISS API (`https://iss.moex.com/iss`) — уже интегрирован в `app/services/moex/` |
| **Стоимость** | Бесплатно (публичный API, delayed quotes) |
| **Доступность** | Список FORTS, daily candles — работает (#4); спот FX — MOEX валютный рынок или официальный курс ЦБ РФ |
| **Инструменты** | Валютные фьючерсы MOEX, совпадают с текущим UI `/instruments` |
| **MVP fit** | In scope: on-demand fetch + Solid Cache, без paid subscriptions |

### Вариант (b): Crypto perpetual funding rate

| Аспект | Оценка |
|--------|--------|
| **Источник данных** | REST/WebSocket Binance, Bybit, OKX и др. — **новая** интеграция |
| **Стоимость** | Public endpoints бесплатны с rate limits; commercial feeds — от ~$50–500/мес за SLA |
| **Доступность** | Funding history публичен; real-time — rate limits, geo-restrictions |
| **Инструменты** | Crypto perpetuals (BTCUSDT, ETHUSDT…) — **не** MOEX валютные фьючерсы |
| **MVP fit** | **Out of scope** per AGENTS.md: «Интеграция с биржевыми API в реальном времени», «Мультибиржевость» |

### Вариант (гибрид)

MOEX базис в MVP + crypto funding post-MVP. Отклонён для MVP: двойное ядро размывает ценность и требует две интеграции до первого релиза. Crypto funding остаётся в backlog, не в MVP.

## Решение

**Принят вариант (a): MOEX базис, контанго/бэквордация и implied cost of carry.**

Обоснование:

1. Существующая интеграция MOEX ISS (#4) — нулевая стоимость данных.
2. Инструменты в коде и UI уже MOEX FORTS.
3. Вариант (b) противоречит MVP boundaries и не решает задачу пользователя MOEX-трейдера.
4. Термин «funding rate» вводил в заблуждение относительно фактических данных.

## Источники данных (MVP)

| Данные | Источник | Endpoint / метод | Стоимость | Статус |
|--------|----------|------------------|-----------|--------|
| Цена фьючерса `F` | MOEX ISS FORTS | `GET /iss/engines/futures/markets/forts/securities/{SECID}/candles.json` | Free (delayed) | **есть** (#4) |
| Список инструментов | MOEX ISS FORTS | `GET /iss/engines/futures/markets/forts/securities.json` | Free | **есть** (#4) |
| Дата экспирации `T` | MOEX ISS FORTS | поле `LASTTRADEDATE` в securities | Free | добавить в #10+ |
| Спот `S` (USD/RUB, EUR/RUB…) | MOEX валютный рынок ISS или курс ЦБ РФ | `GET /iss/engines/currency/markets/selt/securities/{SECID}.json` или CBR XML | Free | **новая** задача |
| Ключевая ставка (теор. carry) | ЦБ РФ | публичная страница / API | Free | ручной ввод или задача #10+ |

## Формулы расчёta (ядро MVP)

Обозначения: `F` — цена фьючерса (close MOEX), `S` — спот базового актива, `T` — календарных дней до экспирации.

### Абсолютный базис

```
B = F − S
```

Положительный `B` → контанго (фьючерс дороже спота).  
Отрицательный `B` → бэквордация.

### Относительный базис (%)

```
b = (F − S) / S × 100%
```

### Годовая implied yield (стоимость удержания)

```
r = (F / S − 1) × (365 / T)
```

Интерпретация: annualized return от покупки спота и короткой позиции по фьючерсу (cash-and-carry) при текущем базисе. Для сравнения с безрисковой ставкой (ключевая ставка ЦБ) — метрика «excess carry».

### MOEX perpetual (`USDRUBF` и аналоги)

Для квази-perpetual MOEX на первом этапе используем **базис к споту** (`B`, `b`) без crypto-style funding. Своп-цена MOEX — отдельная метрика post-MVP.

## Последствия

| Область | Изменение |
|---------|-----------|
| Сервис | `FundingCalculator` → **`BasisCalculator`** (`app/services/basis_calculator.rb`) |
| AGENTS.md / README | Позиционирование: базис MOEX, не crypto funding |
| MVP checklist | «Фандинг» → «**Базис**» |
| Out of scope (MVP) | Crypto-perpetual funding rate, multi-exchange APIs |
| Зависимые задачи | BasisCalculator, spot feed, dashboard metrics — **разблокированы** |

## Отклонено явно (MVP)

- Расчёт funding rate по Binance/Bybit/OKX.
- Позиционирование AtlasQuant как crypto-perpetual analytics tool.

## Ссылки

- MOEX ISS API: https://iss.moex.com/iss/reference/
- Spec #4: MOEX currency futures quotes and chart
- `app/services/moex/` — текущая интеграция
