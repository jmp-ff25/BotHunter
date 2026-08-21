# BotHunter notes

- Domain: explicit outcomes / exceptions for business rules; no Playwright errors leaking up.
- Infrastructure: catch browser/network failures; map to application-level results (`unknown outcome` per ADR-0005).
- Never log secrets or full auth payloads.
