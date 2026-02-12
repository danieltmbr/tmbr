# CLAUDE.md

Vapor web app for capturing thoughts as Posts or Notes on catalogue items (songs, books, movies, podcasts).

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

## Rules

- Discuss before implementing non-trivial features
- Question new abstractions — prefer convenience initializers over new types

## Before Starting

- New modules → read `/.claude/docs/modules.md`
- Schema/relationships → read `/.claude/docs/database.md`
- New Swift types → read `/.claude/docs/patterns.md`
- Complex frontend → read `/.claude/docs/frontend.md`
