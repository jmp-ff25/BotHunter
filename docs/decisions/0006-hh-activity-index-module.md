# ADR-0006: Модуль обслуживания индекса активности HH

Статус: принято

## Контекст

BDD `hh_activity_index.feature` описывает периодическое обслуживание
индекса активности на HH: просмотр вакансий, поднятие резюме,
действия с достижениями и **только** предложенными HH кнопками чата.
Модуль может выполняться каждые N часов, после откликов или параллельно
с ними.

Исходная архитектура объединяла автоматизацию в Automation Orchestrator
без явного выделения activity index.

## Решение

1. В Automation Worker выделить **Activity Index Maintenance** как
   отдельный workflow-модуль с собственным расписанием.
2. Модуль использует HH Adapter (Playwright), но **не** External Action
   Executor для откликов — только read/click workflows без отправки
   пользовательского текста.
3. Результаты прогонов пишутся в `activity_index_runs` и audit trail.
4. Trigger and Recovery Coordinator планирует запуск по интервалу N
   и по политике «after applications / parallel» из профиля.
5. Pause-state и SafetyGuard применяются так же, как к discovery/submit.

## Последствия

- В `docs/architecture/overview.md` добавлен компонент
  Activity Index Maintenance.
- HH Adapter получает `workflows/activity_index.py` и page objects.
- Orchestrator делегирует activity index отдельному handler, не смешивая
  с application submission loop.

## Альтернативы

- Встроить activity actions в discovery workflow — отклонено: разное
  расписание и политики запуска.
- Отдельный OS-процесс — отклонено: избыточно для local-first монолита.
