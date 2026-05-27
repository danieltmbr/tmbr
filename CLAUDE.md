# CLAUDE.md

Vapor web app for capturing thoughts as Posts or Notes on catalogue items (songs, books, movies, podcasts).

## How We Work Together

**Stop and discuss** when:
- The task is non-trivial or ambiguous
- You encounter multiple valid approaches
- Something feels like it needs a new abstraction
- You're unsure which option I'd prefer

Don't pick the easiest path and keep going. Pause, explain the options, and ask.

**Question new types.** Before proposing a new struct/class, ask: can this be a convenience initializer on an existing type instead?

## Stack

Swift 6.0.3 (Swift 5 mode), Vapor 4, Fluent/PostgreSQL, Leaf, Swift Testing

## Commands

```bash
swift build
swift run Backend serve
swift test
swift test --filter CoreTests
```

Run from `tmbr-web/` subdirectory.

For `api-kit` package tests (requires Xcode toolchain, not just CLT):
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path api-kit
```

## Constraints (Always Apply)

- Use `request.commandDB`, never `application.db`
- Command Input types are separate from API payloads — map in controllers
- New modules need computed property extensions for dot-syntax (`Commands+X`, `PermissionScopes+X`)
- Response DTOs go in `Routes/API/Responses/`, not `Payloads/`
- HTML/CSS: semantic elements, target tags not classes, flexbox/grid layout
- JS: vanilla only, Controller pattern with init()/destroy()
- New catalogue types go inside `Catalogue/`, not as top-level modules

## Before Starting

Read the relevant doc:
- Database/schema work → `/.claude/docs/database.md`
- Adding modules → `/.claude/docs/modules.md`
- Frontend (HTML/CSS/JS/Leaf) → `/.claude/docs/frontend.md`
- Swift design patterns → `/.claude/docs/patterns.md`
- Native app networking (`api-kit` package, `RequestLoader`) → `/.claude/docs/native-networking.md`
- Logging, testing, error recovery, post-mortems → `/.claude/docs/quality-assurance.md`

## When Something Breaks

1. Fix it
2. Write (or update) a test that would have caught it
3. Write a post-mortem in `.claude/incidents/` using `.claude/incidents/TEMPLATE.md`
4. If the same component breaks twice — an E2E test is **required** before the fix is considered done
