# Permissions

Composable, single-responsibility permissions accessed via `request.permissions.posts.create`.

## Two Permission Types

**`Permission<Input>`** — Returns `User?`
- For endpoints that are public but behave differently when authenticated
- Example: listing posts returns only published for anon, includes drafts for author

**`AuthPermission<Input>`** — Returns `User` (non-optional)
- For strictly private endpoints
- Throws `.unauthorized` if no user authenticated
- Throws `.forbidden` if user lacks required role
- Returns verified user so commands can use it directly

## Injection Pattern

Permissions are typically injected into commands via their `CommandFactory`:

```swift
CreatePostCommand(
    database: request.commandDB,
    permission: request.permissions.posts.create  // AuthPermissionResolver<Void>
)
```

## Grant Pattern

Inside the command, `permission.grant()` both enforces authorization and provides the authenticated user:

```swift
let user = try await permission.grant()
let post = Post(authorID: user.userID, ...)
```

## Module Files

Each module defines permissions in two files:

- `PermissionScopes+ModuleName.swift` — Declares scope struct with permission properties and computed property on `PermissionScopes` for dot-syntax navigation
- `Permission+ModuleName.swift` — Static permission definitions with actual authorization logic

## Adding Permissions to a New Module

1. Create scope struct in `PermissionScopes+ModuleName.swift`
2. Add computed property on `PermissionScopes` returning the scope
3. Define static permissions in `Permission+ModuleName.swift`

Without the computed property extension, dot-syntax won't resolve.
