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

## Catalogue Nested Module

Unlike other top-level modules, Catalogue (`Sources/App/Modules/Catalogue/`) contains its own inner `ModuleRegistry` with sub-modules: Books, Movies, Songs, Podcasts, and a shared Catalogue controller.

New catalogue item types are added as sub-modules inside Catalogue, not as top-level modules.

## Libraries

- **Core** (`Sources/Core/`) — Shared utilities: Module system, Page pattern, Form handling, Markdown, Validation
- **AuthKit** (`Sources/AuthKit/`) — Authentication with Apple Sign-In, User model, Permission system

## Dot-Syntax Wiring

Both Commands and Permissions use `@dynamicMemberLookup` to enable dot-syntax access (e.g., `request.commands.posts.create`). When adding a new module, writing the command/permission logic alone is not enough — you must also add the extensions that wire it into the lookup chain:

- **Commands**: Add a computed property on `Commands` returning the new collection type, and register the command factories in `Commands+ModuleName.swift`
- **Permissions**: Add a computed property on `PermissionScopes` returning the new scope type, and define the scope struct in `PermissionScopes+ModuleName.swift`

Without these extensions, the dot-syntax won't resolve and the new module's commands/permissions will be inaccessible from the request.
