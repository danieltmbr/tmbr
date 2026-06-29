# Repository Layout

## Packages at a Glance

| Package | Module | Role | Can import |
|---------|--------|------|------------|
| `tmbr-core` | `TmbrCore` | Shared Codable/Sendable types. No platform-specific deps. | Swift stdlib only |
| `tmbr-web` | — | Vapor backend + Leaf frontend (executable) | `TmbrCore`, Vapor, Fluent, Leaf |
| `web-auth` | `WebAuth` | Vapor middleware, Fluent models, JWT, permissions | `TmbrCore`, Vapor, Fluent, JWT |
| `web-core` | `WebCore` | Vapor/Fluent helpers, web Markdown rendering | `TmbrCore`, Vapor, Fluent |
| `tmbr-app` | — | Native SwiftUI apps (three targets — see below) | `TmbrCore`, `AppApi`, `AppCore`, `AppPersistence`, SwiftUI |
| `app-api` | `AppApi` | Networking infra (RequestLoader, Syncer) | `TmbrCore`, Foundation |
| `app-persistence` | `AppPersistence` | SwiftData @Model records + Stores; no SwiftUI | `TmbrCore`, SwiftData |
| `app-core` | `AppCore` | SwiftUI features: Blog, Catalogue, Account, Search | `TmbrCore`, `AppApi`, `AppPersistence`, SwiftUI |

## Native App: three targets over shared packages

`tmbr-app` ships **three apps** from shared local SPM packages. See
`.claude/docs/native-apps-architecture.md` for the full design.

| Module / target | Role | Can import |
|---|---|---|
| `AppPersistence` (lib) | SwiftData @Model records + Stores. No SwiftUI. Testable without a UI host. | `TmbrCore`, SwiftData |
| `AppApi` (lib) | HTTP client, per-endpoint requests, `RequestLoader`, `Syncer`/`SyncGroup` | `TmbrCore`, Foundation |
| `AppCore` (lib) | `@Query` views, `@Observable` models, property wrappers (`@Loader`, `@Upserter`), actions. Imports `AppApi` for `RequestLoader` types only — never constructs loaders. | `TmbrCore`, `AppApi`, `AppPersistence`, SwiftData, SwiftUI |
| **Author** (target) | Owner app: offline-first, `SyncEngine` backend sync | `AppCore`, `AppApi` |
| **Reader** (target) | Public read-only app: on-demand ETag cache | `AppCore`, `AppApi`, `AppPersistence` |
| **Personal** (target) | Private consumer app: `.private` CloudKit, no engine | `AppCore`, `AppPersistence` — never imports `AppApi` |

**Hard dependency rule:** `AppCore` must **never construct a URLSession, hold a baseURL, or
reference AuthProvider, SyncEngine, or CloudKit.** It imports `AppApi` for types only; per-app
config (`apiBaseURL`, `urlSession`, `auth`) is injected at the app layer as env values. Personal
injects no URL → `@Loader`/`@Upserter` are no-ops; the core never branches on app identity.

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

- Packages: kebab-case with prefix indicating platform — `tmbr-*` (shared/top-level), `web-*` (backend-only), `app-*` (native-app-only)
- Swift module names: PascalCase — `import TmbrCore`, `import AppApi`
- Endpoint request structs: `[Verb][Noun]Request` — e.g. `GetSongRequest`, `CreateNoteRequest`

## Cross-Platform Build Rule

Any type added to `tmbr-core` must compile on Linux. After adding types to `tmbr-core`, verify with:

```bash
swift build --package-path tmbr-core
```

If CI runs a Linux build (see `incidents/002`), it will catch Apple-only framework imports automatically. Until then, grep for `import Foundation` in `tmbr-core` and confirm only cross-platform Foundation APIs are used — no `CGSize`, `URL(fileURLWithPath:)` with platform-specific paths, etc.
