# CLAUDE.md — tmbr-app

Native iOS/macOS app built with SwiftUI.

## Stack

Swift 6.0.3 (strict concurrency mode), SwiftUI, Swift Testing, Xcode

## Commands

Build and run via Xcode. For `api-kit` package tests (requires Xcode toolchain, not just CLT):

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path api-kit
```

## Architecture Constraints (Always Apply)

**Shared models**
- Before writing any networking code for a feature, check `tmbr-core` — the response DTO and input payload may already be there from the web implementation. If not, add them to `tmbr-core` first.

**Observable models**
- Use `@MainActor @Observable final class` for any model with state shared across views.
- Inject the model at the root using a single `View` extension modifier (e.g. `.nowPlaying(model)`). Never pass it through `init` parameters.
- Access environment models in views via a custom `@[Subject]` property wrapper — not `@Environment(Model.self)` directly.

**Property wrappers**
- Define `@[Subject]: DynamicProperty` that reads `@Environment(Model.self)` internally.
- Two inits: `init(_ path: KeyPath<Model, Value>)` for read-only, `init(_ path: ReferenceWritableKeyPath<Model, Value>)` for read-write with `$` Binding projection.
- Name for the subject, not the value type: `@NowPlaying`, `@Navigation`.

**Actions**
- Actions are `@MainActor public struct [Verb][Noun]Action: Sendable`.
- Store a single closure: `private let body: @MainActor () -> Void`.
- Two inits: `nonisolated init(_ body: @escaping @MainActor () -> Void = {})` for defaults/tests; `@MainActor init(model:)` bound to the concrete model.
- Implement `@MainActor public func callAsFunction()`.
- One struct = one responsibility. Never merge two actions.

**Environment keys**
- Declare all keys for a feature in one `[Feature]Environment.swift` file using the `@Entry` macro.
- The root injection modifier sets concrete values. Never read action keys from a model or service — only from views.

**Style protocol**
- `public protocol [View]Style: Sendable` with `@MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body`.
- `Configuration` contains only data (bindings + action closures) — no views, no `@State`.
- The public API view's `body` is a single call to `style.makeBody(configuration:)`.
- Concrete styles delegate to a `private struct` that owns all interaction `@State`.
- Styles reached via static accessors (`.system`, `.compact`) — no `public init()`.

**Package structure**
- Dependencies flow downward only: Core → Kit → UI → Feature → App. Never import a higher-tier package.
- `[Domain]Kit` = headless logic (`@Observable` models, no SwiftUI). `[Domain]UI` = controls, property wrappers, actions, styles.
- Module-level access control enforces feature isolation — internal navigation state is never `public`.

**Three apps, one shared core** (see `.claude/docs/native-apps-architecture.md`)
- `tmbr-app` ships **three** targets — **Author** (owner, offline-first backend sync), **Reader**
  (public, read-only ETag cache), **Personal** (private, CloudKit-only) — over one shared local SPM
  package, `AppCore` (+ `AppBackend` for networking, used by Author + Reader only).
- **Hard rule: `AppCore` imports neither networking (`api-kit`/`URLSession`) nor CloudKit.** Per-app
  sync is injected at the app layer as closures (the composition seam), never referenced from the core.
- Write path: actions → SwiftData + an injected `requestSync` closure. Read/refresh: a per-screen
  `@Observable` detail model holding an injected refresh-strategy closure. Same env-key, different
  body per app — that injection point *is* the three-app seam; do not branch on app inside `AppCore`.

**Persistence / sync**
- DTO→record sync orchestration (fetch, index, dedup, reconcile, delete, `context.save()`) lives in a
  `@MainActor` **Store** struct that owns the `ModelContext` (e.g. `PostStore`, `CatalogueStore`).
- `@Model` record extensions hold **only** pure single-record field mapping (`func update(from:)`) and
  value accessors. **Never** a `static func` that takes or touches a `ModelContext`. Never a
  file-scope `private func` helper — helpers belong on the Store as `private` methods.
- See `.claude/docs/swift-patterns.md` §*No Free-Standing Helper Functions* + §*No Namespace / Static-Only Enums for Behaviour*.

**Concurrency**
- `@MainActor` on all `@Observable` classes and action structs.
- `nonisolated` on pure-closure action inits.

## Before Starting

- Native apps architecture (three apps, shared `AppCore`, composition seam) → `.claude/docs/native-apps-architecture.md`
- SwiftUI architecture (Observable, env injection, property wrappers, actions, styles) → `.claude/docs/swiftui-architecture.md`
- Navigation pattern (NavigationModel, scoped feature navigation) → `.claude/docs/navigation.md`
- Networking (RequestLoader, AuthToken, api-kit) → `.claude/docs/networking.md`
- Swift design patterns (both platforms) → `/.claude/docs/swift-patterns.md`
- QA, testing invariants → `/.claude/docs/quality-assurance.md`
- Monorepo cross-package contracts (shared models rule) → `/.claude/docs/repository-layout.md`
