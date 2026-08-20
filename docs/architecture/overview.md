# Архитектура BotHunter

Статус: утверждён

## Цели архитектуры

Архитектура должна поддерживать персональный local-first инструмент,
который длительно выполняет автоматизацию поиска работы и остаётся
управляемым через локальный web-интерфейс.

Основные цели:

- изолировать пользовательский интерфейс от ресурсоёмкой браузерной
  автоматизации;
- не допускать повторных необратимых действий после сбоев;
- сохранять прозрачность решений и выполненных действий;
- позволять добавлять источники вакансий без изменения основной логики;
- поддерживать Windows, Linux и macOS;
- не вводить распределённую инфраструктуру без доказанной необходимости.

## Архитектурный стиль

BotHunter является модульным монолитом в одной кодовой базе,
развёрнутым как два локальных OS-процесса:

- **Web/API Process** — локальный web-интерфейс, настройки, команды,
  состояние, журнал и статистика;
- **Automation Worker Process** — планирование и выполнение
  автоматизации, внешние интеграции и восстановление после сбоев.

Оба процесса используют общие Domain и Application модули, но
не импортируют runtime-компоненты друг друга.

Это разделение не является микросервисной архитектурой. Процессы
устанавливаются, запускаются и обновляются как одно приложение.

## System Context

### Владелец

Единственный пользователь установки. Настраивает профиль, правила
и лимиты, запускает и приостанавливает автоматизацию, просматривает
историю и статистику.

### Внешние системы

- **HH** — источник вакансий и внешнее состояние откликов и сообщений.
- **AI Provider** — анализ текста и генерация материалов через явный
  Application port.
- **Telegram** — доставка уведомлений и запросов вмешательства.

BotHunter передаёт внешним системам только контекст, необходимый
для конкретного пользовательского сценария.

## Containers

### Web/API Process

Локальное Python-приложение, которое:

- слушает только loopback-интерфейс;
- обслуживает web UI и локальный API;
- управляет профилем, настройками, политиками и лимитами;
- записывает команды в durable command inbox;
- отправляет Worker-у локальный signal после фиксации команды;
- отображает heartbeat, состояние автоматизации, журнал и статистику.

Web/API не взаимодействует с HH и Playwright напрямую и не выполняет
необратимые внешние действия.

### Automation Worker Process

Локальный Python-процесс, который:

- выполняет запланированные и пользовательские команды;
- принимает localhost signal и возвращает acknowledgement;
- восстанавливает необработанные команды через recovery scan;
- управляет браузерной автоматизацией и HH adapter;
- обращается к AI и базе знаний через Application ports;
- отправляет Telegram-уведомления;
- записывает heartbeat, решения, попытки и результаты;
- соблюдает pause-state, политики, лимиты и idempotency.

В базовой архитектуре одновременно работает один Worker. Поддержка
нескольких Worker не проектируется заранее.

### Operational Store

Локальная SQLite является авторитетным источником операционного
состояния:

- профиль, настройки, политики и лимиты;
- вакансии и состояние их обработки;
- durable command inbox;
- состояние исполнения и leases;
- intents и результаты внешних действий;
- idempotency records;
- pause-state и heartbeat;
- audit trail и данные статистики.

SQLite не используется как единственный механизм уведомления Worker.
Непосредственный signal передаётся по localhost HTTP, а хранилище
обеспечивает долговечность и восстановление.

### Candidate Document Store

Исходные документы кандидата хранятся в локальной файловой системе
под контролем владельца. Operational Store может содержать их метаданные
и ссылки.

Способ построения retrieval index, embeddings и vector storage
определяется при проектировании RAG-функциональности.

### Managed Browser Runtime

Worker управляет браузерным процессом через Playwright для работы с HH.
Browser Runtime отделён от Domain и Application и рассматривается
как ненадёжная внешняя граница: процесс может завершиться между
действием на площадке и записью результата.

### Python Launcher

Кроссплатформенная команда запуска:

- выполняет необходимые проверки готовности;
- запускает Web/API и Automation Worker;
- перенаправляет их вывод;
- корректно завершает дочерние процессы по команде владельца;
- сообщает о падении одного процесса, не скрывая состояние второго.

Launcher не содержит бизнес-логики и не является отдельным сервисом.
Автоматический бесконечный restart Worker не используется, поскольку
может привести к неконтролируемому повторению внешних действий.

## Крупные компоненты

### Web/API

- **Local Web Delivery** — web UI, локальный API и same-origin boundary.
- **Configuration and Control** — профиль, правила, лимиты,
  запуск, pause и resume.
- **Command Submission** — атомарное создание durable-команды.
- **Query and Reporting** — состояние, audit trail и статистика.
- **Web Repository Ports** — Application contracts для настроек,
  команд и запросов.
- **Worker Signal Port** — Application contract для wake-up signal.
- **Worker Signaler** — localhost signal и обработка acknowledgement.
- **Persistence Adapters** — реализация repository ports.

### Automation Worker

- **Trigger and Recovery Coordinator** — расписание, signals,
  recovery scan, command claim, lease и heartbeat.
- **Automation Orchestrator** — последовательность поиска, анализа,
  оценки, отклика, сообщений и уведомлений.
- **External Action Executor** — единственная прикладная граница
  выполнения необратимых откликов и исходящих сообщений
  на площадках вакансий.
- **Safety and Policy Guard** — политики, лимиты, pause checkpoints,
  idempotency и защита от повторных side effects.
- **Vacancy Query Port** — чтение вакансий и наблюдаемого состояния
  без привязки к площадке.
- **External Action Port** — отправка разрешённых откликов и сообщений.
- **HH Adapter** — реализация query/action ports и Playwright workflows.
- **Candidate Context Port** — получение релевантного опыта кандидата
  без зависимости Application от retrieval-технологии.
- **AI Port** — анализ и генерация без зависимости от SDK провайдера.
- **Notification Port** — уведомления без зависимости от Telegram.
- **Operational Repository Ports** — Application contracts для workflow,
  heartbeat и audit state.
- **Action Unit of Work Port** — согласованный snapshot и условный
  атомарный commit reservation, idempotency record и intent.
- **Operational Persistence Adapters** — команды, состояния, audit,
  heartbeat и idempotency.

## Направление зависимостей

```text
Delivery / Worker Host / Infrastructure Adapters
                         ↓
                  Application Layer
                         ↓
                    Domain Layer
```

Правила зависимостей:

- Domain не зависит от HH, Playwright, SQLite, HTTP, Telegram,
  AI SDK или RAG framework.
- Application определяет use cases и ports.
- Infrastructure реализует ports и зависит от Application.
- Web/API и Worker являются composition roots и runtime hosts.
- Новый источник реализует Vacancy Query Port и только поддерживаемые
  capabilities External Action Port, затем регистрируется
  в composition root без изменения Domain и Application.
- Конкретный AI Provider и retrieval engine заменяются
  инфраструктурными adapters.
- Межпроцессное взаимодействие проходит только через согласованный
  command inbox и signal/ack contract.

## Координация процессов

### Постановка команды

1. Web/API валидирует запрос владельца.
2. Команда с уникальным идентификатором транзакционно записывается
   в durable command inbox.
3. После успешной фиксации Web/API отправляет Worker-у localhost signal.
4. Worker подтверждает получение signal, но не завершение команды.
5. Worker атомарно закрепляет команду за собой на ограниченный lease.
6. Итог исполнения сохраняется в Operational Store.

Если signal не доставлен, команда не теряется. Recovery scan Worker-а
находит её в durable inbox.

### Heartbeat и recovery

Worker периодически записывает heartbeat. Устаревший heartbeat
показывает Web/API, что автоматизация недоступна.

Истечение lease не означает, что внешнее действие безопасно повторить.
Оно запускает reconciliation состояния команды и связанных действий.

Точные HTTP payloads, интервалы signal, heartbeat, lease и recovery scan
определяются на этапе проектирования реализации.

## Безопасность действий на площадках вакансий

### Единая граница side effects

Automation Orchestrator не вызывает External Action Port напрямую.
Все необратимые отклики и исходящие сообщения на площадках вакансий
проходят через External Action Executor.

Executor выполняет обязательную последовательность:

1. Через Action Unit of Work Port открывается согласованный snapshot
   актуальных policy, лимитов, pause-state и idempotency state.
2. Safety and Policy Guard выполняет чистую доменную проверку snapshot.
3. Reservation, idempotency record и intent фиксируются условным
   атомарным commit, который отклоняется, если snapshot устарел.
4. Успешный commit является точкой начала действия. После него Executor
   вызывает External Action Port.
5. Наблюдаемый результат сохраняется как outcome.
6. Отсутствие доказуемого результата переводит действие
   в `unknown outcome`.

HH Adapter реализует External Action Port, но не принимает решения
о допустимости действия.

Pause, полученная после commit intent, применяется перед следующим
действием и не отменяет уже начатое. Это устраняет ложное обещание
атомарности между локальным состоянием и внешней площадкой.

### Idempotency

Используются два независимых уровня:

- command idempotency предотвращает повторное исполнение одной команды;
- business-action deduplication предотвращает повторный отклик
  или сообщение для одного внешнего объекта.

### Intent и результат

Перед необратимым действием Worker сохраняет intent. После наблюдаемого
подтверждения сохраняется результат.

Если Worker или Browser Runtime завершился между этими шагами,
действие получает состояние `unknown outcome`.

### Unknown outcome

Для `unknown outcome` Worker:

1. сначала сверяет наблюдаемое состояние с внешней площадкой;
2. подтверждает результат, если он доказуем;
3. повторяет только доказанно безопасное действие;
4. иначе приостанавливает соответствующий сценарий
   и уведомляет владельца.

`unknown outcome` не переводится в обычный автоматический retry.
Архитектура не обещает exactly-once для внешних браузерных действий.

### Pause

Durable pause-state хранится в Operational Store. Worker проверяет его:

- перед получением новой работы;
- перед началом команды;
- перед каждым необратимым действием на площадке вакансий;
- между безопасными шагами workflow.

Pause не отменяет уже отправленное действие. Гарантируется остановка
на ближайшей безопасной контрольной точке.

## Данные и секреты

- Operational Store и Candidate Document Store располагаются локально.
- Секреты и credentials не хранятся в открытом виде в SQLite,
  документах, логах или audit trail.
- Доступ к секретам проходит через отдельную инфраструктурную границу;
  конкретное кроссплатформенное решение выбирается при проектировании.
- Данные, передаваемые AI Provider, минимизируются до необходимого
  контекста.
- Локальный web-интерфейс не публикуется в сеть и слушает loopback.
- State-changing web-запросы должны быть защищены от подделки,
  несмотря на локальный режим работы.

## Расширяемость источников вакансий

HH является первым adapter, но не частью core.

Контракт источника охватывает возможности площадки, необходимые
Application: поиск и чтение вакансий, наблюдение состояния, отправку
откликов и работу с сообщениями.

Различия площадок выражаются capabilities adapter-а. Application
не должно предполагать, что каждый источник поддерживает одинаковый
набор действий.

Добавление источника означает реализацию Vacancy Query Port
и только тех action capabilities, которые площадка действительно
поддерживает, после чего adapter регистрируется в composition root.
Application не планирует неподдерживаемые действия.

Изменение Domain или Application только ради подключения источника
с уже предусмотренными capabilities считается признаком неверной
границы.

## Browser Recorder

Browser Recorder не входит в runtime-границу BotHunter. Это отдельный
development-support tool, который собирает технические факты,
`session.json` и Playwright trace для последующего создания BDD
и Page Objects.

Артефакты Recorder не являются операционным состоянием BotHunter
и не передаются в Domain или Application.

## Отложенные решения

До проектирования конкретной функциональности не фиксируются:

- Python package tree, классы и сигнатуры ports;
- web-framework и способ построения UI;
- HTTP routes и signal payloads;
- SQLite schema, индексы и параметры подключения;
- форматы idempotency keys и точные state machines;
- интервалы heartbeat, leases и recovery scan;
- retry и backoff для конкретных интеграций;
- AI SDK и конкретный провайдер;
- chunking, embeddings и retrieval index;
- Playwright selectors и browser contexts;
- конкретный cross-platform secret store.

## Связанные решения

- [ADR-0001: локальное развёртывание и топология процессов](../decisions/0001-local-deployment-and-process-topology.md)
- [ADR-0002: модульные границы и ports](../decisions/0002-modular-boundaries-and-ports.md)
- [ADR-0003: локальное хранение данных](../decisions/0003-local-data-storage.md)
- [ADR-0004: гибридная координация Worker](../decisions/0004-hybrid-worker-coordination.md)
- [ADR-0005: безопасное выполнение внешних действий](../decisions/0005-safe-external-action-execution.md)
