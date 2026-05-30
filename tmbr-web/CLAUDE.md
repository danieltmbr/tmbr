# CLAUDE.md — tmbr-web

Vapor 4 backend and Leaf web frontend.

## Stack

Swift 6.0.3 (Swift 5 mode), Vapor 4, Fluent/PostgreSQL, Leaf, Swift Testing

## Commands

Run from the `tmbr-web/` directory:

```bash
swift build
swift run Backend serve
swift test
swift test --filter CoreTests
```

## Constraints (Always Apply)

- Use `request.commandDB`, never `application.db`
- Command Input types are separate from API payloads — map in controllers
- New modules need computed property extensions for dot-syntax (`Commands+X`, `PermissionScopes+X`)
- Response DTOs go in `Routes/API/Responses/`, not `Payloads/`
- HTML/CSS: semantic elements, target tags not classes, flexbox/grid layout
- JS: vanilla only, Controller pattern with `init()`/`destroy()`
- New catalogue types go inside `Catalogue/`, not as top-level modules
- **Shared API models:** when adding a new API response DTO or input payload, add it to `tmbr-core` first as a `Codable & Sendable` type. Add Fluent/Vapor conformances in a separate extension in `tmbr-web`. Check `tmbr-core` before declaring any type the native app may also need.

## Before Starting

Read the relevant doc:
- Database/schema work → `.claude/docs/database.md`
- Module system, commands, permissions, controllers → `.claude/docs/modules.md`
- Frontend (HTML/CSS/JS/Leaf) → `.claude/docs/frontend.md`
- QA backlog (specific tests to write) → `.claude/docs/qa-backlog.md`
- Monorepo cross-package contracts → `/.claude/docs/repository-layout.md`
- Swift design patterns → `/.claude/docs/swift-patterns.md`
- QA, testing invariants → `/.claude/docs/quality-assurance.md`
