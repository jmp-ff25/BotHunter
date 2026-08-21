---
name: bothunter-recorder
description: >-
  Records HH browser sessions with BotHunter Browser Recorder and turns
  artifacts into Page Objects. Use when exploring HH UI, creating locators,
  or working with tools/recorder, session.json, or trace.zip.
---

# BotHunter Browser Recorder

## When to use

- Exploring HH flows before HH Adapter implementation.
- Capturing locators for Page Objects.
- **Not** for production automation runtime (Recorder is outside `src/bothunter/`).

## Record a session

```bash
python -m tools.recorder record \
  --output-dir ./recordings/<session-name> \
  --start-url "https://hh.ru/"
```

Close the browser or press Ctrl+C to finish.

## Artifacts

| File | Purpose |
|------|---------|
| `session.json` | Structured event index for agent analysis |
| `trace.zip` | Playwright trace for deep inspection |

Format: `tools/recorder/README.md`, design: `docs/design/browser-recorder.md`.

## Pipeline

```text
Record session (Recorder)
    → Analyze session.json + trace
    → Create Page Objects
    → Wire into HH Adapter workflows
```

Page Objects location:

```text
src/bothunter/infrastructure/hh/pages/
```

## Page Object rules

- Locators and atomic browser actions only.
- No business rules, policies, or limits.
- Follow `.cursor/rules/playwright.mdc`.
- Do not commit traces/sessions with credentials.

## Priority HH flows to record

1. Login / session state
2. Vacancy search and filters
3. Vacancy card and application form
4. Activity index maintenance screens

## Related

- Task spec: `docs/tasks/browser-recorder.md`
