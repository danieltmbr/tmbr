# Native iOS & macOS App — Architecture & Plan

## Motivation

The tmbr backend has a full catalogue API (songs, albums, books, movies, podcasts). A native app is needed for:

1. **Better writing experience** — dedicated app vs browser
2. **MusicKit / Now Playing** — detect what's playing, save to catalogue in one tap
3. **Share Extension** — share a URL from any app → tmbr recognises it and creates the catalogue entry automatically

---

## Architecture Decision

**Chosen: Monorepo + shared SPM package (`tmbr-core`) + separate Xcode project (`tmbr-app`)**

| Option | Rejected because |
|--------|-----------------|
| Separate repo | API types live in backend; changes cause constant friction and risk drift |
| Add iOS targets to backend Package.swift | MusicKit/Share Extension need Xcode entitlements; backend pulls in Vapor/Fluent/Linux deps iOS must never see |
| **Monorepo (chosen)** | Atomic commits across backend + client; shared types; independent build systems |

No Xcode workspace needed — when `tmbr-core` is added as a local package dep to `tmbr.xcodeproj`, Xcode surfaces its sources in the navigator automatically.

---

## Naming Convention

All components: `tmbr-<role>` for directory/package names (same pattern as `swift-collections`, `swift-algorithms`).
Swift module name inside each package uses PascalCase for `import`: `tmbr-core` → `import TmbrCore`.

---

## Repository Layout

```
tmbr/                       ← git root
├── tmbr-web/               ← Vapor backend (renamed from tmbr/)
│   ├── Package.swift       ← target: Backend; local dep on ../tmbr-core
│   └── Sources/App/        ← source dir stays as-is
├── tmbr-core/              ← shared Swift package → import TmbrCore
│   ├── Package.swift       ← no external deps; pure Codable/Sendable types
│   └── Sources/TmbrCore/
│       ├── Responses/      ← 11 Response DTOs (Vapor conformances stripped)
│       ├── Enums/          ← Access.swift
│       ├── Shared/         ← Hyperlink.swift
│       └── IDs/            ← SongID, AlbumID, NoteID, etc.
└── tmbr-app/               ← Xcode project (multiplatform SwiftUI)
    ├── tmbr.xcodeproj      ← bundle: me.tmbr.app; targets iOS 26, macOS 26
    ├── Shared/
    ├── iOS/                ← includes TmbrShare extension
    └── macOS/
```

---

## Stages

### ✅ Stage 0 — Architecture decision & plan
Documented here. Branch: `native-app-setup` (based on `catalogue-stage-9`).

### ✅ Stage 1 — Create `tmbr-core` shared package
- `tmbr-core/Package.swift` — target `TmbrCore`; no external deps
  - ⚠️ Platforms set to `.iOS(.v18), .macOS(.v15)` (server toolchain Swift 6.0.3 doesn't support v26 in PackageDescription — update when setting up the Xcode project on a newer toolchain)
- 11 Response DTOs in `Sources/TmbrCore/Responses/` — public, Codable, Sendable; Vapor conformances stripped
- `Access` enum → `Sources/TmbrCore/Enums/Access.swift`
- `PostState` enum → `Sources/TmbrCore/Enums/PostState.swift` (extracted from `Post.State`)
- `Hyperlink` → `Sources/TmbrCore/Shared/Hyperlink.swift`
- ID typealiases → `Sources/TmbrCore/IDs.swift`

### ✅ Stage 2 — Update `tmbr-web` backend
- `tmbr/` → `tmbr-web/` renamed via `git mv`
- `Package.swift`: local dep on `../tmbr-core`; `App` target renamed → `Backend`
- Vapor conformances re-added as `+Vapor.swift` extensions per Response type
- `import TmbrCore` added to ~90 source files
- `swift build` ✅ — Build complete
- `swift test` ⚠️ — `CoreTests` fails with `no such module 'Testing'` (pre-existing issue, unrelated to this change)

### ⬜ Stage 3 — Create `tmbr-app` Xcode project *(manual in Xcode)*
- `File → New → Project → Multiplatform App`
- Product: `tmbr`, bundle: `me.tmbr.app`, min targets: iOS 26 / macOS 26
- `File → Add Package Dependencies → Add Local → ../tmbr-core`

### ⬜ Stage 4 — Add Share Extension *(manual in Xcode)*
- `File → New → Target → Share Extension` → name: `TmbrShare`
- iOS first; share `TmbrCore` with main app via App Group

---

## First Features (after scaffolding)

1. **Auth** — Sign in with Apple → backend JWT endpoint
2. **MusicKit Now Playing** — `MusicPlayer.shared.state` + `currentEntry` → POST to songs API
3. **Share Extension** — URL in → metadata preview endpoint → catalogue entry created

---

## Verification Checklist

- [ ] `cd tmbr-web && swift build` passes
- [ ] `swift test` passes
- [ ] `tmbr.xcodeproj` builds for iOS simulator in Xcode
- [ ] `TmbrCore` types visible in both backend build and Xcode navigator
