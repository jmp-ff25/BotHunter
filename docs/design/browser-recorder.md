# Browser Recorder — проектирование реализации

Статус: на согласовании  
Задача: `docs/tasks/browser-recorder.md`  
Фаза: 1 (первая production-реализация после каркаса)

## Назначение

Локальный CLI-инструмент для записи сессии исследования HH (и других
сайтов) через Playwright. Результат — `session.json` + `trace.zip`
для анализа агентом и создания Page Objects.

Recorder **не** часть Web/API и Worker, **не** пишет в Operational Store.

## Границы

| Внутри | Снаружи |
|--------|---------|
| Запуск браузера, codegen-подобная запись | BDD, Page Objects, HH Adapter |
| Нормализация событий в session.json | AI-анализ (Cursor / агент) |
| Сохранение Playwright trace | Автоматизация откликов |

## Расположение

```text
tools/recorder/
  __main__.py           # CLI entry: python -m tools.recorder
  session.py            # модель session.json
  recorder.py           # Playwright binding, event capture
  trace.py              # trace lifecycle
  cli.py                # argparse

tests/unit/tools/recorder/
tests/integration/tools/recorder/
```

## CLI

```text
python -m tools.recorder record \
  --output-dir ./recordings/<name> \
  --start-url "https://hh.ru/..."
```

Опции:

- `--output-dir` (обязательно) — каталог для `session.json` и `trace.zip`;
- `--start-url` — начальный URL;
- `--headless` — по умолчанию `false` (исследование в headed режиме).

Команда `record` блокирует процесс до Ctrl+C или закрытия браузера.

## Формат session.json

Версионированный JSON. Trace дублирует детали DOM — в JSON только
структура для агента.

```json
{
  "version": 1,
  "started_at": "ISO-8601",
  "ended_at": "ISO-8601",
  "start_url": "https://...",
  "events": [
    {
      "seq": 1,
      "timestamp": "ISO-8601",
      "type": "navigation",
      "url": "https://..."
    },
    {
      "seq": 2,
      "timestamp": "ISO-8601",
      "type": "click",
      "url": "https://...",
      "locators": {
        "role": ["button", "Откликнуться"],
        "test_id": null,
        "css_hint": "button[data-qa=...]"
      },
      "screenshot_ref": null
    }
  ]
}
```

Типы событий (минимальный набор v1): `navigation`, `click`, `fill`,
`select`, `keyboard`, `dialog`.

`locators` — best-effort: role+name, test-id, короткий css-hint;
полные XPath/CSS не обязательны, если есть trace.

## Playwright Trace

- Включать `context.tracing.start` при старте записи.
- `tracing.stop(path=.../trace.zip)` при завершении.
- Trace — источник деталей; session.json — индекс для агента.

## Зависимости

- `playwright` (Python);
- stdlib + typing; без зависимости от `src/bothunter`.

## Тесты

| Уровень | Что проверяем |
|---------|-----------------|
| Unit | сериализация session.json, валидация schema, seq/timestamp |
| Integration | mock Playwright page events → корректный JSON; trace file exists |
| E2E | опционально: короткая запись на static HTML fixture |

BDD для Recorder не требуется (инструмент разработки, не поведение BotHunter).

## Выход Recorder → HH Adapter

После записи сессий по сценариям (логин, поиск, карточка, отклик,
индекс активности) агент создаёт:

```text
src/bothunter/infrastructure/hh/pages/
  login_page.py
  search_page.py
  vacancy_page.py
  application_page.py
  activity_index_page.py
```

Page Object — только локаторы и атомарные действия; бизнес-правила
остаются в Application/Worker.

## Критерии готовности фазы 1

- CLI записывает сессию и создаёт оба артеfacta;
- unit-тесты на session model;
- integration-тест с mocked events;
- документирован формат session.json в `tools/recorder/README.md`
  (кратко, при реализации).
