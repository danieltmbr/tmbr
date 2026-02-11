# Commands

Business logic decoupled from HTTP handlers via composable, single-responsibility commands. Each command typically performs one focused DB operation (fetch, create, update, delete).

## Access

- Dot syntax: `request.commands.posts.create(input)`
- Defined as `CommandFactory` statics in `Commands+ModuleName.swift`

## Database Access

**CRITICAL**: Always use `request.commandDB`, never `application.db`.

`commandDB` is a `@TaskLocal` database instance defined in `CommandContext` that enables transaction support.

## Transactions

Wrap multiple commands for atomicity:

```swift
request.commands.transaction { commands in
    let song = try await commands.songs.create(songInput)
    let notes = try await commands.notes.batchCreate(notesInput)
    return SongResponse(song: song, notes: notes)
}
```

- Transaction sets `CommandContext.database` (a `@TaskLocal`) to the transaction DB
- All commands read from `request.commandDB`, so they transparently participate
- Outside a transaction, `commandDB` falls back to `application.db`
- Nested transaction calls detect existing transaction and reuse it

## Input Types

- Commands define their own `Input` types, NOT API payloads
- Same command is reused by both REST API and Web controllers
- Caller (API or Web) maps its endpoint-specific payload into command's input
- Using a request payload directly as command input is an **anti-pattern**

## Adding Commands to a New Module

1. Define command structs with their `Input` types
2. Create `CommandFactory` statics for each command
3. Add `Commands+ModuleName.swift` with computed property on `Commands`

Without the computed property extension, dot-syntax won't resolve.
