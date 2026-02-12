# Permissions

## Access Pattern

```swift
request.permissions.posts.create
```

## When Choosing Permission Type

Use **`Permission<Input>`** (returns `User?`) for public endpoints with auth-aware behavior.

Use **`AuthPermission<Input>`** (returns `User`) for private endpoints — throws `.unauthorized` or `.forbidden`.

## When Injecting Permissions

Pass to commands via `CommandFactory`:

```swift
CreatePostCommand(
    database: request.commandDB,
    permission: request.permissions.posts.create
)
```

## When Checking Authorization

Call `grant()` to enforce and get the user:

```swift
let user = try await permission.grant()
let post = Post(authorID: user.userID, ...)
```

## When Adding Permissions to a New Module

1. Create scope struct in `PermissionScopes+ModuleName.swift`
2. Add computed property on `PermissionScopes` returning the scope
3. Define static permissions in `Permission+ModuleName.swift`

Without the computed property extension, dot-syntax won't resolve.
