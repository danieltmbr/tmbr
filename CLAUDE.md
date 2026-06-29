# CLAUDE.md

Tmbr is a platform for capturing thoughts as Posts or Notes on catalogue items (songs, books, movies, podcasts). The project is a monorepo with several packages and a shared workspace:

- **tmbr-web** — Vapor 4 backend + Leaf web frontend
- **tmbr-core** — Shared Swift types (Codable/Sendable DTOs, enums, ID typealiases) used by both platforms
- **tmbr-app** — Native iOS/macOS SwiftUI app (three targets: Author, Reader, Personal)
- **app-api** — Networking library (RequestLoader, Syncer) — native app only
- **app-persistence** — SwiftData @Model records + Stores — native app only
- **app-core** — SwiftUI feature modules (Blog, Catalogue, Account, Search) — native app only
- **web-auth** — Vapor middleware, Fluent models, JWT/permissions — backend only
- **web-core** — Vapor/Fluent helpers, web Markdown rendering — backend only

## How We Work Together

**Stop and discuss** when:
- The task is non-trivial or ambiguous
- You encounter multiple valid approaches
- Something feels like it needs a new abstraction
- You're unsure which option I'd prefer

Don't pick the easiest path and keep going. Pause, explain the options, and ask.

**Question new types.** Before proposing a new struct/class, ask: can this be a convenience initializer on an existing type instead?

## Repository Layout

| Package | Module | Purpose | Platform |
|---------|--------|---------|----------|
| `tmbr-core` | `TmbrCore` | Shared Codable/Sendable types — no platform-specific deps | Both |
| `tmbr-web` | — | Vapor backend + Leaf frontend (executable) | Linux/macOS |
| `tmbr-app` | — | Native SwiftUI app — three Xcode targets (Author/Reader/Personal) | iOS/macOS |
| `app-api` | `AppApi` | Networking infrastructure (RequestLoader, Syncer) | iOS/macOS |
| `app-persistence` | `AppPersistence` | SwiftData @Model records + Stores; no SwiftUI | iOS/macOS |
| `app-core` | `AppCore` | SwiftUI feature modules; imports AppApi + AppPersistence | iOS/macOS |
| `web-auth` | `WebAuth` | Vapor middleware, Fluent models, JWT, permissions | macOS/Linux |
| `web-core` | `WebCore` | Vapor/Fluent helpers, web Markdown rendering | macOS/Linux |

**tmbr-core is the shared contract.** API response DTOs and input payloads used by both the backend and native app live here as pure `Codable & Sendable` types. `tmbr-web` adds Fluent/Vapor conformances in extensions. `tmbr-app` imports them directly. Never add Apple-framework-specific types to `tmbr-core` — it must compile on Linux.

## Before Starting

Read the relevant doc first:
- **Web backend/frontend work** → `tmbr-web/CLAUDE.md`
- **Native app work** → `tmbr-app/CLAUDE.md`
- **Swift design patterns** (both platforms) → `.claude/docs/swift-patterns.md`
- **QA, testing invariants, logging, post-mortems** → `.claude/docs/quality-assurance.md`
- **Monorepo layout, cross-package contracts** → `.claude/docs/repository-layout.md`

## When Something Breaks

1. Fix it
2. Write (or update) a test that would have caught it
3. Write a post-mortem in `.claude/incidents/` using `.claude/incidents/TEMPLATE.md`
4. If the same component breaks twice — an E2E test is **required** before the fix is considered done
