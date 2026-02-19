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
swift run App serve
swift test
swift test --filter CoreTests
```

Run from `tmbr/` subdirectory.

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
