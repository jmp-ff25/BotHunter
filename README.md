# BotHunter

Персональный local-first инструмент для автоматизации поиска работы.
Помогает одному владельцу находить подходящие вакансии, оценивать
соответствие резюме, отправлять отклики в рамках настроенных правил
и поддерживать индекс активности на HH.

Документация: [`docs/project-vision.md`](docs/project-vision.md) ·
[`docs/development-process.md`](docs/development-process.md) ·
[`docs/bdd/`](docs/bdd/) · [`docs/design/`](docs/design/)

## Разработка

Требуется Python 3.12.

```bash
python -m venv .venv
.venv\Scripts\pip install -e ".[dev]"
playwright install chromium
pytest
```

## Browser Recorder

```bash
python -m tools.recorder record --output-dir ./recordings/hh --start-url "https://hh.ru/"
```

Подробнее: [`tools/recorder/README.md`](tools/recorder/README.md).

## Правовое примечание

BotHunter автоматизирует поиск работы конкретного пользователя
и не предназначен для массового сбора данных, спама, обхода ограничений
или злоупотребления платформой. При реализации необходимо соблюдать
актуальные условия HH и, где возможно, использовать официальный API.
