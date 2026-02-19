# Module System

The app uses a modular architecture defined in `Sources/Core/Module/`.

## Core Protocols

- **Configuration** protocol: Setup phase for dependencies, migrations, middleware
- **Module** protocol: Extends Configuration with `boot()` for route registration
- **ModuleRegistry**: Orchestrates multiple modules

## Registration

Modules are registered in `Sources/App/entrypoint.swift`:

```swift
ModuleRegistry(
    configurations: [.logging, .database, .commands, .renderer],
    modules: [.rss, .manifest, .authentication, .notifications,
              .gallery, .previews, .notes, .posts, .catalogue, .debug]
)
```

## Module Structure

Each module in `Sources/App/Modules/` follows this pattern:

- `ModuleName.swift` — Module definition implementing `configure()` and `boot()`
- `Models/` — Fluent database models and migrations
- `Commands/` — Business logic commands (Create, Edit, Delete, Fetch, List)
- `Routes/API/` — REST API controllers and `Responses/` DTOs
- `Routes/Web/` — Web controllers and Pages
- `Permissions/` — Permission scopes for the module
- `Payloads/` — Endpoint-specific request DTOs (API payloads, query parameters, etc.)

Response DTOs (e.g., `PostResponse`, `ImageResponse`) belong in `Routes/API/Responses/`, not in `Payloads/`. They are REST-specific objects — the API equivalent of Web Page view models.

## Adding a New Module

1. Create module folder with standard structure (see above)
2. Add computed property on `Commands` in `Commands+ModuleName.swift`
3. Add computed property on `PermissionScopes` in `PermissionScopes+ModuleName.swift`
4. Register module in `entrypoint.swift`

Without the computed property extensions, dot-syntax won't resolve.

## Catalogue Nested Module

Unlike other top-level modules, Catalogue (`Sources/App/Modules/Catalogue/`) contains its own inner `ModuleRegistry` with sub-modules: Books, Movies, Songs, Podcasts, and a shared Catalogue controller.

New catalogue item types are added as sub-modules inside Catalogue, not as top-level modules. See `database.md` for adding new catalogue item types.

## Libraries

- **Core** (`Sources/Core/`) — Shared utilities: Module system, Page pattern, Form handling, Markdown, Validation
- **AuthKit** (`Sources/AuthKit/`) — Authentication with Apple Sign-In, User model, Permission system

## Command Pattern

Business logic is decoupled from HTTP handlers via composable, single-responsibility commands.

### Access Pattern

```swift
request.commands.posts.create(input)
```

### Critical Rule

**Always use `request.commandDB`**, never `application.db`. This is a `@TaskLocal` database instance that enables transaction support.

### Transactions

When multiple commands need to run atomically:

```swift
request.commands.transaction { commands in
    let song = try await commands.songs.create(songInput)
    let notes = try await commands.notes.batchCreate(notesInput)
    return SongResponse(song: song, notes: notes)
}
```

The transaction sets `CommandContext.database` (a `@TaskLocal`) to the transaction DB. Since all commands read from `request.commandDB`, they transparently participate in the transaction. Outside a transaction, `commandDB` falls back to `application.db`. Nested transaction calls detect an existing transaction and reuse it.

### Command Input Types

Commands define their own `Input` types, not API payloads. The same command is reused by both API and Web controllers. The caller maps its endpoint-specific payload into the command's input type.

### Adding Commands to a Module

1. Define command structs with `Input` types
2. Create `CommandFactory` statics for each command
3. Add computed property on `Commands` in `Commands+ModuleName.swift`

## Permission Pattern

Permissions follow the same composable pattern as commands.

### Access Pattern

```swift
request.permissions.posts.create
```

### Permission Types

- **`Permission<Input>`** — Returns `User?`. For public endpoints with auth-aware behavior (e.g., listing posts returns only published for anonymous, includes drafts for author).
- **`AuthPermission<Input>`** — Returns `User` (non-optional). For private endpoints. Throws `.unauthorized` if no user, `.forbidden` if wrong role.

### Injection and Grant

Inject permissions into commands via `CommandFactory`:

```swift
CreatePostCommand(
    database: request.commandDB,
    permission: request.permissions.posts.create
)
```

Inside the command, `grant()` enforces authorization and provides the user:

```swift
let user = try await permission.grant()
let post = Post(authorID: user.userID, ...)
```

### Adding Permissions to a Module

1. Create scope struct in `PermissionScopes+ModuleName.swift`
2. Add computed property on `PermissionScopes` returning the scope
3. Define static permissions in `Permission+ModuleName.swift`
