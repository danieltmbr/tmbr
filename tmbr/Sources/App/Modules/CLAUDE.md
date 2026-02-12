# Modules

## Rules

- Place Response DTOs in `Routes/API/Responses/`, not `Payloads/`
- Add new catalogue item types inside `Catalogue/`, not as top-level modules
- Define command Input types separately from API payloads — map payloads to inputs in controllers

## When Adding a New Module

1. Create module folder with standard structure
2. Add computed property on `Commands` in `Commands+ModuleName.swift`
3. Add computed property on `PermissionScopes` in `PermissionScopes+ModuleName.swift`
4. Register module in `entrypoint.swift`

Without the computed property extensions, dot-syntax won't resolve.

## Before Implementing Business Logic

Read these — they define the core patterns for all feature work:

- Commands (transactions, Input types, commandDB): `/tmbr/Sources/Core/Commands/CLAUDE.md`
- Permissions (auth, grant pattern, injection): `/tmbr/Sources/AuthKit/Permissions/CLAUDE.md`

## Before Adding a New Module

Read `/.claude/docs/modules.md` for ModuleRegistry and Configuration protocol details.
