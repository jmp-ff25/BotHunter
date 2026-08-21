# BotHunter Core — проектирование реализации

Статус: на согласовании  
Основа: `docs/architecture/overview.md`, ADR 0001–0007

## Слои и зависимости

```text
web/  worker/  infrastructure/
         ↓
    application/   (ports + use cases)
         ↓
      domain/
```

Infrastructure реализует ports; web/worker — composition roots.
Domain не импортирует Playwright, SQLite, Telegram, AI SDK.

## Application ports (основные)

| Port | Назначение | Реализация |
|------|------------|------------|
| `ProfileRepository` | резюме, prefs, политики, лимиты | SQLite adapter |
| `CommandRepository` | durable inbox | SQLite adapter |
| `WorkerSignaler` | wake-up localhost HTTP | infrastructure |
| `OperationalRepository` | вакансии, audit, heartbeat, pause | SQLite adapter |
| `VacancyQueryPort` | чтение вакансий с площадки | HH adapter |
| `ExternalActionPort` | **только отклики** | HH adapter + Executor |
| `CandidateContextPort` | релевантный контекст из CV/docs | RAG adapter (файлы + index) |
| `AIPort` | оценка, текст для полей | provider adapter |
| `NotificationPort` | Telegram stats / alerts | Telegram adapter |
| `ActionUnitOfWorkPort` | idempotency + intent commit | SQLite + SafetyGuard |

## Worker: use cases и orchestration

### Trigger and Recovery Coordinator

- Cron-like schedule для activity index (интервал N часов из настроек).
- Обработка command inbox, lease, recovery scan (ADR-0004).
- Heartbeat в Operational Store.

### Automation Orchestrator

Последовательность workflow (не один монолитный класс — отдельные handlers):

1. `VacancyDiscoveryWorkflow`
2. `VacancyEvaluationWorkflow`
3. `ApplicationSubmissionWorkflow` (+ form completion sub-step)
4. `ActivityIndexMaintenanceWorkflow` — **отдельный модуль**, может
   запускаться по расписанию или после batch откликов (BDD).

Orchestrator проверяет pause-state и SafetyGuard перед каждым шагом.

### External Action Executor (ADR-0005)

Единственная точка необратимых HH-действий:

- submit application;
- **не** send custom employer messages.

Перед действием: snapshot + conditional commit через `ActionUnitOfWorkPort`.

### Safety and Policy Guard

- daily/monthly limits;
- exclusion/required words;
- compensation range;
- dedup по vacancy id;
- pause checkpoints.

## Web/API

Minimal first version:

- REST или HTMX — **решение отложено до фазы 2**; достаточно FastAPI
  + простые шаблоны или JSON API для локального UI.
- Только loopback bind.
- Команды: start/pause/resume automation, CRUD profile settings.
- Read-only: audit, statistics, worker heartbeat.

Web не вызывает Playwright и HH.

## Operational Store (SQLite) — логические сущности

Детальная DDL — при реализации фазы 2; логические таблицы:

| Сущность | Назначение |
|----------|------------|
| `profile` | CV metadata, compensation, word lists |
| `automation_state` | running/paused, last heartbeat |
| `commands` | durable inbox |
| `vacancies` | discovered + evaluation outcome |
| `applications` | submission attempts, status |
| `activity_index_runs` | HH activity maintenance history |
| `audit_events` | append-only trail |
| `idempotency_keys` | side-effect dedup |
| `statistics_snapshots` | aggregates for UI/Telegram |

Индексы и миграции — Alembic или простой versioned SQL на старте.

## HH Adapter

```text
infrastructure/hh/
  adapter.py              # VacancyQueryPort + ExternalActionPort
  browser_session.py      # Playwright context lifecycle
  pages/                  # Page Objects from Recorder
  workflows/
    discovery.py
    evaluation_read.py
    application.py
    activity_index.py
```

Workflows используют pages; Application вызывает только adapter/workflow
facade через ports.

**Activity index workflow:** просмотр вакансий, поднятие резюме,
клики по **предложенным HH** кнопкам чата — без ввода текста.

## Candidate Context (RAG)

См. `docs/tasks/rag.md`. Application видит только `CandidateContextPort`:

```python
# conceptual — не production code
def query_relevant_context(self, field_prompt: str, vacancy_context: str) -> str: ...
```

Реализация: локальные файлы CV + chunk index; embeddings provider
настраивается в infrastructure, не в BDD.

## Уведомления Telegram

Только статистика (BDD profile + audit):

- daily applications count;
- daily rejections;
- monthly total applications.

Без автоматических сообщений работодателям.

## Launcher

`python -m bothunter` или скрипт `bothunter`:

- проверка Python 3.12, playwright browsers (optional check);
- spawn Web/API + Worker;
- graceful shutdown обоих процессов.

## Тестовая стратегия (core)

- **Domain/Application:** unit-тесты на PolicyGuard, orchestration decisions.
- **Infrastructure:** integration с in-memory SQLite, mocked Playwright.
- **BDD:** pytest-bdd поверх application services с test doubles.
- **E2E:** отдельный медленный слой против real HH — только после
  стабилизации mocked integration.

Fixtures: `tests/conftest.py` — db session, fake ports, paused automation.

## Связь с Browser Recorder

Recorder → Page Objects → HH workflows → ports.
Без Recorder можно начать каркас (фазы 0–2), но HH automation (фаза 5+)
блокируется отсутствием исследованных локаторов.
