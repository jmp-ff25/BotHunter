# ADR-0007: Без автоматической переписки с работодателями

Статус: принято

## Контекст

`docs/project-vision.md` и BDD исключили автоматические сообщения
работодателям. Telegram-уведомления ограничены статистикой откликов.
Исходная архитектура упоминала исходящие сообщения в External Action Port
и Automation Orchestrator.

## Решение

1. **External Action Port** покрывает только **отправку откликов**
   (application submission) на площадках вакансий.
2. Автоматическая отправка произвольных сообщений работодателям
   **не реализуется**.
3. HH Activity Index может нажимать **только предложенные HH** элементы
   чата (BDD), без ввода текста — это не External Action Port messaging.
4. **Notification Port** — только уведомления владельцу (Telegram stats).

## Последствия

- Обновлены формулировки в `docs/architecture/overview.md` (Orchestrator,
  External Action Port).
- BDD area employer messaging отсутствует; реализация не планируется.
- External Action Executor не получает use case «send message».

## Альтернативы

- Оставить messaging в port «на будущее» — отклонено: противоречит vision
  и усложняет safety model без утверждённого поведения.
