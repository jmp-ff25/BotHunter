# План реализации BotHunter

Статус: на согласовании  
Этап: 5 — проектирование реализации  
Основа: утверждённые `docs/bdd/*.feature`, `docs/architecture/`, ADR 0001–0007

## Цель этапа

Определить, **как** реализовать утверждённое поведение, не написав
production-код. После одобрения этого плана начинается этап 6.

## Архитектурные уточнения по BDD

BDD первого контура потребовал уточнить архитектуру:

1. **Нет автоматической переписки с работодателями** — External Action Port
   покрывает только отклики; чаты HH для индекса активности используют
   отдельные read/click workflows без отправки собственных сообщений.
2. **Отдельный модуль HH Activity Index Maintenance** — периодическое
   обслуживание индекса активности в Worker, с расписанием и режимами
   «после откликов» / «параллельно».
3. **Заполнение анкеты отклика** — через Candidate Context Port и AI Port
   в рамках application workflow, без проникновения RAG framework в Domain.

См. ADR-0006 и ADR-0007.

## Предлагаемая структура кодовой базы

```text
src/bothunter/
  domain/                 # правила, политики, value objects
  application/            # use cases, ports (interfaces)
  infrastructure/         # sqlite, telegram, ai, hh/playwright, filesystem
  web/                    # composition root Web/API
  worker/                 # composition root Automation Worker

tools/
  recorder/               # Browser Recorder (вне runtime BotHunter)

tests/
  bdd/                    # pytest-bdd step definitions + features symlink/copy
  unit/
  integration/
  e2e/

docs/bdd/                 # исполняемые спецификации (источник истины)
```

Recorder **не** импортируется из `src/bothunter/` и не входит в Domain/Application.

## Порядок реализации

| Фаза | Что реализуется | BDD | Зачем |
|------|-----------------|-----|-------|
| **0** | Каркас: Python 3.12, pytest, pytest-bdd, ruff, структура каталогов | — | основа CI и тестов |
| **1** | **Browser Recorder** | — | session.json + trace для HH Page Objects |
| **2** | Launcher, Web/API skeleton, Worker skeleton, SQLite bootstrap | — | процессы и persistence |
| **3** | Configuration: резюме, предпочтения, политики, лимиты | profile_policies | фундамент правил |
| **4** | Automation control: start/pause/resume, durable pause | automation_control | управляемость |
| **5** | Vacancy discovery + HH query adapter (read-only) | vacancy_discovery | первый HH workflow |
| **6** | Vacancy evaluation + Candidate Context + AI Port | vacancy_evaluation | оценка по CV |
| **7** | Application submission + External Action Executor | application_submission | side effects |
| **8** | Application form completion | application_form_completion | нестандартные поля анкеты |
| **9** | HH Activity Index Maintenance | hh_activity_index | индекс активности |
| **10** | Audit trail & statistics + Telegram stats notifications | audit_trail, profile (notifications) | наблюдаемость |

Фазы 1 и 2–4 могут частично пересекаться, но **Recorder** не зависит
от Operational Store BotHunter.

## Матрица тестирования по BDD

| BDD feature | Unit | Integration | E2E (Playwright) |
|-------------|------|-------------|------------------|
| profile_policies_and_limits | PolicyGuard, validators | Web repos + SQLite | Настройки через local UI |
| automation_control | Pause-state rules | Command inbox + worker signal | Pause/resume через UI |
| vacancy_discovery | Word/range filters | HH adapter (mocked browser) | Discovery на HH (позже) |
| vacancy_evaluation | — | AI + Candidate Context ports (mocked) | — |
| application_submission | SafetyGuard, idempotency | Executor + HH action (mocked) | Submit flow на HH (позже) |
| application_form_completion | — | Form filler + context (mocked) | — |
| hh_activity_index | Schedule policy | HH maintenance workflows (mocked) | Activity actions на HH (позже) |
| audit_trail_and_statistics | Aggregations | Audit repo + queries | Statistics UI |

**Правило:** не поднимать сценарий на e2e, если его можно надёжно проверить
на integration с mocked Playwright/HH.

**BDD:** все `docs/bdd/*.feature` исполняются через pytest-bdd; step definitions
живут в `tests/bdd/steps/`, по одному модулю на feature-файл.

## Зависимости между фазами

```text
Recorder ──► HH Page Objects ──► HH Adapter
                                    │
Configuration ──► Automation control ──► Discovery ──► Evaluation
                                                          │
                                    Application submission ◄┘
                                          │
                              Form completion + Activity index (parallel)
                                          │
                              Audit trail & statistics
```

## Вне scope первой реализации

- Многопользовательский режим, несколько Worker, удалённое развёртывание.
- Автоматические сообщения работодателям.
- Источники вакансий кроме HH.
- Полноценный web UI (достаточно minimal API + простых форм на ранних фазах).

## Следующий шаг после одобрения

Этап 6, фаза 0–1: каркас репозитория и **Browser Recorder**.
