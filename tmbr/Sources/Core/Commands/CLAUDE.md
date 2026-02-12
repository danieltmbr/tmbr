# Commands

## Rules

- **Always use `request.commandDB`**, never `application.db`
- Define command Input types separately from API payloads
- Map payloads to command inputs in controllers — never use payloads directly as inputs

## Access Pattern

```swift
request.commands.posts.create(input)
```

## When Running Multiple Commands Atomically

Wrap in a transaction:

```swift
request.commands.transaction { commands in
    let song = try await commands.songs.create(songInput)
    let notes = try await commands.notes.batchCreate(notesInput)
    return SongResponse(song: song, notes: notes)
}
```

- `commandDB` is a `@TaskLocal` — transactions set it to the transaction DB
- All commands read from `commandDB`, so they transparently participate
- Nested transaction calls detect existing transaction and reuse it
- Outside transactions, `commandDB` falls back to `application.db`

This is why `commandDB` is critical — using `application.db` bypasses transaction support.

## When Adding Commands to a New Module

1. Define command structs with `Input` types
2. Create `CommandFactory` statics for each command
3. Add computed property on `Commands` in `Commands+ModuleName.swift`

Without the computed property extension, dot-syntax won't resolve.
