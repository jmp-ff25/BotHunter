---
name: bothunter-workflow
description: >-
  Guides BotHunter development stages from docs/development-process.md.
  Use when starting work, finishing a stage, creating work reports,
  or when the user asks about process stages, approvals, or what to do next.
---

# BotHunter Development Workflow

## Before any significant task

1. Read `docs/development-process.md`.
2. Identify the current stage (vision → architecture → BDD → design → implementation → QA → sync).
3. Read `docs/tasks/<task>.md` if the work maps to a task spec.
4. Do **not** skip stages or proceed without user approval.

## Stage gates

| Stage | Deliverable | Stop until user approves |
|-------|-------------|--------------------------|
| 2 Vision | `docs/project-vision.md` | Yes |
| 3 Architecture | `docs/architecture/`, ADR | Yes |
| 4 BDD | `docs/bdd/*.feature` | Yes |
| 5 Design | `docs/design/` | Yes |
| 6 Implementation | Code + tests | Per phase |
| 7 QA | pytest, ruff, security checks | Yes |
| 8 Sync | BDD ↔ arch ↔ code ↔ docs | Yes |

## After completing significant work

Provide a summary in chat:

- stage status;
- what was done;
- changed files;
- architectural changes;
- issues and solutions;
- checks and results;
- next step.

Then **stop** and wait for explicit approval.

## Work reports

Create `docs/work-reports/YYYY-MM-DD-<topic>.md` only after user approves the result.
Use `docs/work-reports/TEMPLATE.md`. Do not commit reports for rejected or unverified work.

## Language

- Documentation and reports: Russian.
- Code, identifiers, Gherkin: English.

## Related

- Rules: `.cursor/rules/development-process.mdc`
- Agent map: `AGENTS.md`
