# CLAUDE.md

## About

Vapor web app for capturing thoughts as Posts or Notes on catalogue items (songs, books, movies, podcasts). Preview-based linking enables any entity to own Notes and be referenced by Posts.

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

## Collaboration

- Discuss before implementing non-trivial features
- Question new abstractions — prefer convenience initializers over new types

## Gotchas

- `.with()` is eager loading, NOT a SQL join — use `.join()` before `.filter(Model.self, ...)`
- Always use `request.commandDB`, never `application.db`

## Testing

Uses Swift Testing: `@Suite`, `@Test`, `#expect`

## Libraries

- **Core** (`Sources/Core/`) — Module system, Page pattern, Form handling, Markdown, Validation
- **AuthKit** (`Sources/AuthKit/`) — Authentication with Apple Sign-In, User model, Permission system

## Before Working On

- New modules → `/.claude/docs/modules.md`
- Schema/relationships → `/.claude/docs/database.md`
- New Swift types → `/.claude/docs/patterns.md`
- Complex frontend → `/.claude/docs/frontend.md`
