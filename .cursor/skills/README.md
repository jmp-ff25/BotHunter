# Skills BotHunter

Два каталога skills в проекте:

| Каталог | Содержимое |
|---------|------------|
| `.agents/skills/` | Установлены через [skills.sh](https://skills.sh/) CLI (`skills-lock.json`) |
| `.cursor/skills/` | Проектные skills BotHunter (workflow, BDD, recorder) |

## Установленные skills (`.agents/skills/`)

| Skill | Источник | Назначение |
|-------|----------|------------|
| `test-driven-development` | [obra/superpowers](https://skills.sh/obra/superpowers/test-driven-development) | Red-green-refactor |
| `verification-before-completion` | [obra/superpowers](https://skills.sh/obra/superpowers/verification-before-completion) | Доказательства перед «готово» |
| `systematic-debugging` | [obra/superpowers](https://skills.sh/obra/superpowers/systematic-debugging) | Отладка по корневой причине |
| `webapp-testing` | [anthropics/skills](https://skills.sh/anthropics/skills/webapp-testing) | Python Playwright для local UI |
| `playwright-cli` | [microsoft/playwright-cli](https://skills.sh/microsoft/playwright-cli/playwright-cli) | CLI-исследование браузера (опционально) |
| `python-testing-patterns` | [wshobson/agents](https://skills.sh/wshobson/agents/python-testing-patterns) | pytest, fixtures, mocks |
| `python-type-safety` | [wshobson/agents](https://skills.sh/wshobson/agents/python-type-safety) | Type hints, typing |
| `python-project-structure` | [wshobson/agents](https://skills.sh/wshobson/agents/python-project-structure) | Пакеты, модули |
| `python-error-handling` | [wshobson/agents](https://skills.sh/wshobson/agents/python-error-handling) | Исключения, границы |

Для BotHunter см. `BOTUHUNTER.md` в каталогах skills, где есть дополнения.

Rule `.cursor/rules/python-implementation.mdc` требует читать применимые skills
при работе с `**/*.py`.

## Agents (`.cursor/agents/`)

| Agent | Назначение |
|-------|------------|
| `architecture-consultant` | Архитектура, ADR, readonly |
| `implementation-agent` | Реализация кода, TDD, pytest |

## Проектные skills (`.cursor/skills/`)

| Skill | Назначение |
|-------|------------|
| `bothunter-workflow` | Этапы `docs/development-process.md` |
| `bothunter-bdd` | pytest-bdd, feature-файлы |
| `bothunter-recorder` | Browser Recorder → Page Objects |

## Установка и обновление

```bash
# из корня репозитория
npx skills add <owner/repo> --skill <name> --agent cursor -y --copy
npx skills update -y
npx skills list
```

Восстановление из lock-файла:

```bash
npx skills experimental_install
```

## Приоритеты BotHunter

1. **HH exploration** — `bothunter-recorder` (Python), не `playwright-cli`.
2. **Тесты** — pytest + mocked Playwright; e2e — последний resort.
3. **Rules** (`.cursor/rules/`) не заменяются skills: bdd, testing, playwright, security.

## Добавление skill

1. Проверить на [skills.sh](https://skills.sh/) (security audit).
2. `npx skills add ... --agent cursor -y --copy`
3. Обновить эту таблицу.
4. При необходимости добавить `BOTUHUNTER.md` в каталог skill.
