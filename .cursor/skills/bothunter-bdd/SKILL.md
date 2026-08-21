---
name: bothunter-bdd
description: >-
  Implements and maintains BotHunter BDD with pytest-bdd.
  Use when writing Gherkin scenarios, step definitions, or connecting
  docs/bdd features to executable tests.
---

# BotHunter BDD (pytest-bdd)

## Sources of truth

- Executable features: `docs/bdd/*.feature` (English).
- Russian mirrors: `docs/bdd/*.feature.ru.md` — documentation only, not executed.
- Conventions: `docs/bdd/README.md`, rule `.cursor/rules/bdd.mdc`.

## Rules

- BDD describes **behavior**, not implementation (no CSS, Playwright, RAG, SQLite).
- One feature file per functional area.
- Step definitions: `tests/bdd/steps/` (create when implementing BDD execution).
- Use pytest-bdd; run via `pytest tests/bdd/`.

## Adding or changing scenarios

1. Update English `.feature` first.
2. Mirror literally in `.feature.ru.md` if Russian mirror exists for that file.
3. Implement step definitions with test doubles before real infrastructure.
4. Prefer integration tests with mocked ports over e2e unless BDD requires a browser.

## pytest-bdd layout (target)

```text
tests/bdd/
  conftest.py
  steps/
    profile_policies_steps.py
    automation_control_steps.py
    ...
```

Link features in `pytest.ini` or `conftest.py`:

```python
pytest_plugins = ["pytest_bdd"]
# scenarios("docs/bdd/profile_policies_and_limits.feature")
```

## When not to use BDD

- Browser Recorder (`tools/recorder`) — dev tool, no Gherkin.
- Pure unit tests for domain rules — use `tests/unit/` directly.

## Related

- `docs/design/implementation-plan.md` — BDD to phase mapping.
