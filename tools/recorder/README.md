# Browser Recorder

CLI tool for recording HH exploration sessions.

## Usage

```bash
python -m tools.recorder record \
  --output-dir ./recordings/hh-login \
  --start-url "https://hh.ru/"
```

Or after install:

```bash
bothunter-recorder record --output-dir ./recordings/hh-login --start-url "https://hh.ru/"
```

Close the browser window or press Ctrl+C to finish recording.

## Artifacts

- `session.json` — structured event index for agent analysis.
- `trace.zip` — Playwright trace for detailed inspection.

## session.json (version 1)

| Field | Description |
|-------|-------------|
| `version` | Schema version (currently `1`). |
| `started_at` / `ended_at` | ISO-8601 UTC timestamps. |
| `start_url` | Initial URL. |
| `events` | Ordered list of captured interactions. |

Event types: `navigation`, `click`, `fill`, `select`, `keyboard`, `dialog`.

Each event has `seq`, `timestamp`, `type`, and optional `url`, `locators`,
`value`, `key`, `dialog_type`, `message`.

`locators` contains best-effort hints: `role`, `test_id`, `css_hint`.
