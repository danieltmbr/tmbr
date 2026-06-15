# Repository Layout

## Packages at a Glance

| Package | Role | Can import |
|---------|------|------------|
| `tmbr-core` | Shared Codable/Sendable types. No platform-specific deps. | Swift stdlib only |
| `tmbr-web` | Vapor backend + Leaf frontend | `tmbr-core`, Vapor, Fluent, Leaf |
| `tmbr-app` | Native SwiftUI apps (three targets — see below) | `tmbr-core`, `api-kit`, `AppCore`, SwiftUI, MusicKit |
| `api-kit` | Networking infra (RequestLoader, AuthToken) | Swift stdlib only |

## Native App: three targets over one shared core

`tmbr-app` ships **three apps** from one shared local SPM package (`AppCore`). See
`.claude/docs/native-apps-architecture.md` for the full design.

| Module / target | Role | Can import |
|---|---|---|
| `AppCore` (lib) | SwiftData schema, `@Query` views, `@Observable` models, property wrappers, actions. The composition seam lives here as injected closures. | `tmbr-core`, SwiftData, SwiftUI |
| `AppBackend` (lib) | api-kit request structs + shared pull/push helpers | `AppCore`, `tmbr-core`, `api-kit` |
| **Author** (target) | Owner app: offline-first, `SyncEngine` backend sync | `AppCore`, `AppBackend` |
| **Reader** (target) | Public read-only app: on-demand ETag cache | `AppCore`, `AppBackend` |
| **Personal** (target) | Private consumer app: `.private` CloudKit, no engine | `AppCore` only (no networking) |

**Hard dependency rule:** `AppCore` must import **neither networking (`api-kit`/`URLSession`) nor
CloudKit.** That isolation is what lets one core serve all three apps; per-app sync is injected as
closures at the app layer.

## What Belongs in `tmbr-core`

`tmbr-core` must compile on Linux — it has no Apple-framework dependencies. It holds types that both the backend and the native app need:

- **API response DTOs** — e.g. `SongResponse`, `NoteResponse`, `AuthResponse`
- **API input payloads** — e.g. `CreateNotePayload`, `SignInPayload`
- **Shared enums** — e.g. `Access`, item type identifiers
- **ID typealiases** — e.g. `SongID`, `NoteID`

**What does NOT belong in `tmbr-core`:**
- Fluent models or Vapor protocol conformances (those go in `tmbr-web` as extensions)
- SwiftUI or UIKit types
- Apple-only Foundation types (no `CGSize`, no `UIImage`, no `NSAttributedString`)
- App-specific business logic

## Shared API Models Rule

The monorepo exists to avoid declaring the same type twice. Violating this creates drift — the native app ends up with a `Song` that has different fields than the backend's `SongResponse`.

**When adding a new API endpoint to `tmbr-web`:**
1. Define the response DTO and any input payload in `tmbr-core` first (`Codable & Sendable`)
2. Add Fluent/Vapor conformances as extensions in `tmbr-web` — never in `tmbr-core`
3. Import `TmbrCore` in the `tmbr-web` controller and return the shared type

**When implementing the native side of an existing web feature:**
1. Check `tmbr-core` first — the models may already be there from the web implementation
2. If they're missing, add them to `tmbr-core` before writing any native networking code
3. Use the shared type as `RequestLoader.Response` — no separate native DTO needed

## Naming Conventions

- Packages: `tmbr-<role>` (kebab-case)
- Swift module names: PascalCase — `import TmbrCore`, `import ApiKit`
- Endpoint request structs: `[Verb][Noun]Request` — e.g. `GetSongRequest`, `CreateNoteRequest`

## Cross-Platform Build Rule

Any type added to `tmbr-core` must compile on Linux. After adding types to `tmbr-core`, verify with:

```bash
swift build --package-path tmbr-core
```

If CI runs a Linux build (see `incidents/002`), it will catch Apple-only framework imports automatically. Until then, grep for `import Foundation` in `tmbr-core` and confirm only cross-platform Foundation APIs are used — no `CGSize`, `URL(fileURLWithPath:)` with platform-specific paths, etc.
