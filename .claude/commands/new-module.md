Add a new non-catalogue backend module. The module name will be provided as an argument or in context.

Read `tmbr-web/.claude/docs/modules.md` completely before starting. The module system, command pattern, and permission pattern are all described there in detail.

Work through these steps in order.

---

## Step 1 — Module Scaffold

Create the folder and core files in `Sources/App/Modules/[ModuleName]/`:

```
[ModuleName]/
├── [ModuleName].swift              — Module definition
├── Models/
│   └── [ModelName].swift          — Fluent model + migration
├── Commands/
│   └── Commands+[ModuleName].swift — CommandFactory computed property extension
├── Permissions/
│   └── PermissionScopes+[ModuleName].swift
│   └── Permission+[ModuleName].swift
├── Routes/
│   ├── API/
│   │   ├── [ModuleName]APIController.swift
│   │   └── Responses/[ModelName]Response.swift
│   └── Web/
│       └── [ModuleName]WebController.swift
└── Payloads/
    └── [ModelName]Payload.swift
```

## Step 2 — Module Definition

In `[ModuleName].swift`:

```swift
struct [ModuleName]Module: Module {
    func configure(_ app: Application) throws {
        app.migrations.add(Create[ModelName]Migration())
    }
    func boot(_ routes: RoutesBuilder) throws {
        let protected = routes.grouped(SessionAuthenticator())
        try protected.register(collection: [ModuleName]WebController())
        try protected.register(collection: [ModuleName]APIController())
    }
}
```

## Step 3 — Dot-Syntax Extensions

These are required — without them, `request.commands.[moduleName]` and `request.permissions.[moduleName]` won't resolve.

**`Commands+[ModuleName].swift`:**
```swift
extension Commands {
    var [moduleName]: [ModuleName]CommandCollection {
        [ModuleName]CommandCollection(database: commandDB)
    }
}
```

**`PermissionScopes+[ModuleName].swift`:**
```swift
extension PermissionScopes {
    var [moduleName]: [ModuleName]PermissionScope {
        [ModuleName]PermissionScope(request: request)
    }
}
```

## Step 4 — Commands

- Define `Input` types (separate from API payloads — controllers map between them)
- Use `request.commandDB`, never `application.db`
- Inject permissions into commands via `CommandFactory`; call `permission.grant()` inside the command

## Step 5 — API Controller

- Returns JSON — never renders Leaf
- Response DTOs go in `Routes/API/Responses/` not `Payloads/`
- After writing the response DTO, add it to `tmbr-core` as `Codable & Sendable`

## Step 6 — Register Module

In `Sources/App/entrypoint.swift`, add to the `modules` array:

```swift
modules: [..., .[moduleName]]
```

Add the computed property to the `ModuleRegistry` extension if it doesn't already use dot-syntax.

---

## Final Checklist

- [ ] `Commands+[ModuleName].swift` computed property extension present
- [ ] `PermissionScopes+[ModuleName].swift` computed property extension present
- [ ] `request.commandDB` used everywhere — zero occurrences of `application.db`
- [ ] Command `Input` types are separate from API payloads
- [ ] Response DTOs in `Routes/API/Responses/`
- [ ] Response DTO added to `tmbr-core` as `Codable & Sendable`
- [ ] Module registered in `entrypoint.swift`
- [ ] Migration registered and applies cleanly
- [ ] At least one command test (create + ownership)
