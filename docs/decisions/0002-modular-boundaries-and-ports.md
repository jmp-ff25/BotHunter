# ADR-0002: Модульные границы и ports

Статус: принято  
Дата: 2026-08-20

## Context

Первым источником вакансий является HH, но BotHunter должен позволять
подключать другие площадки без изменения Domain и Application.

Основная логика также не должна зависеть от Playwright, Telegram,
конкретного AI Provider, retrieval framework или способа хранения.

При этом полноценная формальная hexagonal architecture для каждого
внутреннего вызова создала бы ненужные абстракции.

## Decision

Использовать направленные модульные границы:

```text
Delivery / Worker Host / Infrastructure Adapters
                         ↓
                  Application Layer
                         ↓
                    Domain Layer
```

Domain содержит бизнес-правила и не зависит от инфраструктуры.

Application координирует use cases и определяет ports только
на границах с изменяемыми или внешними возможностями:

- Vacancy Query Port;
- External Action Port;
- Candidate Context Port;
- AI Port;
- Notification Port;
- Web Repository Ports;
- Operational Repository Ports;
- Action Unit of Work Port;
- Worker Signal Port;
- secret provider boundary.

Infrastructure реализует ports:

- HH Adapter и Page Objects, реализующие query/action ports;
- AI Provider Adapter;
- Telegram Adapter;
- Candidate Context Adapter;
- SQLite repositories;
- cross-platform secret storage adapter.

Web/API и Automation Worker являются runtime hosts и composition roots.

Возможности источника описываются явно. Application не предполагает,
что каждая площадка поддерживает одинаковые действия.

Automation Orchestrator использует Vacancy Query Port для чтения.
External Action Port доступен только через External Action Executor,
который применяет Safety and Policy Guard и сохраняет intent
до необратимого действия.

Каждый источник реализует Vacancy Query Port и только поддерживаемые
action capabilities. Отсутствующая capability не эмулируется
и не планируется Application.

## Consequences

Положительные последствия:

- особенности HH и Playwright не проникают в core;
- AI Provider и retrieval engine можно заменять;
- новый источник добавляется новым adapter и регистрацией;
- Domain и Application можно тестировать без браузера и внешних API;
- ports создаются на реальных границах, а не вокруг каждого класса.

Отрицательные последствия:

- требуется поддерживать contracts между слоями;
- различия capabilities площадок должны быть смоделированы явно;
- composition roots должны корректно связывать реализации;
- неправильное размещение интерфейсов может создать искусственные
  абстракции.

Изменение Domain или Application только ради подключения нового
источника считается сигналом для пересмотра границы adapter-а.
