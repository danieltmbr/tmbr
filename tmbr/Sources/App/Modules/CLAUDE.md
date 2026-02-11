# Modules

Each module in `Sources/App/Modules/` follows this pattern:

- `ModuleName.swift` — Module definition implementing `configure()` and `boot()`
- `Models/` — Fluent database models and migrations
- `Commands/` — Business logic commands (Create, Edit, Delete, Fetch, List)
- `Routes/API/` — REST API controllers and `Responses/` DTOs
- `Routes/Web/` — Web controllers and Pages
- `Permissions/` — Permission scopes for the module
- `Payloads/` — Endpoint-specific request DTOs (API payloads, query parameters, etc.)

Response DTOs (e.g., `PostResponse`, `ImageResponse`) belong in `Routes/API/Responses/`, not in `Payloads/`. They are REST-specific objects — the API equivalent of Web Page view models.

**Catalogue is a nested module.** Unlike other top-level modules, Catalogue contains its own inner `ModuleRegistry` with sub-modules: Books, Movies, Songs, Podcasts, and a shared Catalogue controller. New catalogue item types are added as sub-modules inside Catalogue, not as top-level modules.

## Commands

Business logic accessed via `request.commands.posts.create(input)`.

- Commands define their own Input types, NOT API payloads
- Caller (API or Web) maps payload → command input
- **Full documentation:** `/tmbr/Sources/Core/Commands/CLAUDE.md`

## Permissions

Authorization accessed via `request.permissions.posts.create`.

- **Full documentation:** `/tmbr/Sources/AuthKit/Permissions/CLAUDE.md`

## Dot-Syntax Wiring

Both Commands and Permissions use `@dynamicMemberLookup` for dot-syntax access. When adding a new module:

- **Commands**: Add computed property on `Commands` returning the new collection type, register factories in `Commands+ModuleName.swift`
- **Permissions**: Add computed property on `PermissionScopes` returning the new scope type, define scope struct in `PermissionScopes+ModuleName.swift`

Without these extensions, dot-syntax won't resolve.
