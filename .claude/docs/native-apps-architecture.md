# Native Apps Architecture: Three Apps, One Shared Core

## Why this document exists

The native app effort went through three rounds of foundation work. The current branch shipped a
single monolithic offline-first app backed by the Vapor website, documented as a **two-product**
vision (the now-superseded `two-product-architecture.md`). Building it clarified the real product
shape: it is **three** distinct apps, not two. This document is the canonical record of that pivot,
the target architecture, and the rationale — so later work follows a designed path rather than
rediscovering it.

Companion: `.claude/docs/plans/offline-first-native-app.md` (the staged roadmap).

---

## The three apps

| | **Reader** (App 1) | **Author** (App 2) | **Personal** (App 3) |
|---|---|---|---|
| **Who** | Public consumers | The owner (you) | Each consumer (private) |
| **Content** | The owner's *public* blog + catalogue | The owner's *full* blog + catalogue + notes | The user's *own* private catalogue + notes |
| **Read/Write** | Read-only | Read + author | Read + author |
| **Local store** | SwiftData as **cache** | SwiftData as **full mirror** | SwiftData as **full mirror** |
| **Freshness** | On-demand, lazy: cache only what's viewed; fetch+upsert on open (ETag/`304` later) | Eager full delta sync; push-then-pull; tombstones; offline writes | CloudKit auto-mirror across the user's Apple devices |
| **Backend** | Vapor public read API (new, additive) | Vapor sync API (built) | **None** — iCloud private DB only |
| **Auth** | None / optional | Sign in with Apple | iCloud account (implicit) |

**Reader's data-flow** (the genuinely new piece): open UI → `@Query` renders cached SwiftData
instantly → background fetch → upsert into SwiftData (UI refreshes reactively). **Lists and detail are
both fetched lazily on open** — only viewed items get cached. There is **no** `syncState`, no
tombstones, no push — it is a stale-while-revalidate cache, not a sync engine.

**First build (now):** Reader runs against the **existing** per-type list + orphan endpoints,
**unauthenticated** (guests are already scoped to `access == .public`) — no new backend. ETag /
`If-None-Match` → `304` (skip unchanged upserts) and a dedicated public read API / per-item detail JSON
are **deferred optimizations**, layered later under the same fetch+upsert abstraction.

---

## The pivot (from two products to three apps)

The prior vision was "two products from one core": Product 1 = owner app + future guest read-mode,
backed by the website; Product 2 = future CloudKit-only consumer app. The pivot splits Product 1's
two audiences into two apps and keeps Product 2 as the third:

**Why Reader is its own app, not a config of Author.** They share the schema and the `@Query`-driven
presentation, but their data-flow is nearly opposite: Reader is read-only, lazy/on-demand ETag
caching of just-viewed items for a *public* audience; Author is read-write, eager full-mirror with
delta sync + tombstones + offline writes for *one* author. A single configurable binary would carry
two incompatible sync subsystems and two entitlement profiles. They share *presentation*, not
*plumbing* — so they share a **core**, not a binary. This also retires the old `offlineSyncEnabled`
"guest read-mode" toggle (a two-product compromise, never built): Reader replaces it with a
purpose-built app.

**Why Author and Personal are the symmetric pair.** They are identical code: offline-first, full
local mirror, the same write actions. The *only* difference is the `ModelContainer` and the sync
composition — Author has a `SyncEngine`; Personal has a `.private` CloudKit container and no engine.
This is exactly the "composition, not protocol" seam from the prior doc; the pivot keeps it intact.

**Why CloudKit (not the backend) for Personal.** Unchanged: zero backend cost, no UGC App Store
review, no GDPR/account-deletion duty, no moderation/support burden. Each user's data lives in their
own iCloud. Apple-only reach for other users was explicitly judged acceptable.

---

## Target architecture

### Shared core + three compositions

Two repo-root SPM packages back the three app targets (renamed in the package restructure):

```
        ┌──────────────────────── core-app  (module CoreApp) ──────────────────────────┐
        │  No networking, no CloudKit, no sync engine.                                  │
        │    • SwiftData @Model records + SyncState   (CloudKit-constrained schema)     │
        │    • DTO→record upsert helpers (import CoreTmbr only, ModelContext-based)      │
        │    • @Query-driven views (Blog/Catalogue/detail/editors), capability-gated    │
        │    • @Observable models (BlogModel, CatalogueModel, per-screen detail models) │
        │    • property wrappers (@Blog, @Catalogue, @Post …), environment keys         │
        │    • write Actions (Create/Update/Delete) → SwiftData + injected requestSync() │
        └──────────────────────────────────────────────────────────────────────────────┘
        ┌──────────────────────── core-api  (module CoreApi) ──────────────────────────┐
        │  HTTP client + per-endpoint requests + RequestLoader.syncAll  ← Reader+Author │
        └──────────────────────────────────────────────────────────────────────────────┘
                  ▲                        ▲                          ▲
        ┌─────────┘            ┌───────────┘             ┌────────────┘
 ┌──────┴───────┐     ┌────────┴─────────┐      ┌────────┴─────────┐
 │ Reader (1)   │     │  Author (2)      │      │  Personal (3)    │
 │ fetch+upsert │     │  SyncEngine      │      │ .private CloudKit│
 │ (lazy, unauth)│    │ (delta/push/pull)│      │  ModelContainer  │
 │ plain container│   │ plain container  │      │ requestSync = {} │
 │ read-only UI │     │ auth + bg sync   │      │ no networking    │
 └──────────────┘     └──────────────────┘      └──────────────────┘
```

`CoreApp` + `CoreApi` are the (former) `AppCore` + `AppBackend` from the original sketch, now standalone
root packages (`core-app`, `core-api`) sharing `core-tmbr`/`CoreTmbr` DTOs. Reader + Author link
`CoreApi`; **Personal does not** (no networking).

**The invariant that makes one core serve three apps:** `CoreApp` depends on **SwiftData + CoreTmbr DTOs
+ injected closures only** — never on `SyncEngine`, a Reader fetcher, `URLSession`, `CoreApi`, or
CloudKit. Each app injects its own composition.

### The seam is the existing Action pattern — no new protocol

The house style (`swift-patterns.md`, `swiftui-architecture.md`) is closures-wrapped-in-structs over
protocols. The seam reuses it. A `SyncCoordinator` protocol was rejected because its CloudKit body
would be all no-ops — a fake abstraction.

**Write path.** Actions write to SwiftData and call an injected `requestSync` closure:
- Author: `requestSync = { try? await syncEngine.runSync() }`
- Personal: `requestSync = {}` (CloudKit mirrors automatically)
- Reader: no write actions surfaced (read-only)

The current `BlogModel`/`CatalogueModel` and write actions capture `SyncEngine` directly; the one
real refactor of the extraction is replacing that capture with the injected `requestSync`.

### Read/refresh seam: a per-object `@Observable` detail model

Detail-screen data + refresh lives in a small `@MainActor @Observable` model
(`PostDetailModel`, `CatalogueItemDetailModel`) — the RunKit `RunLibrary`/`RunPlayer` shape, which
puts async on an observable **source**, not inside a `DynamicProperty`. (An earlier
`Resource`-DynamicProperty sketch that hosted async lifecycle in a wrapper was dropped — the one
risky deviation from that reference.)

The model owns: the observed record, the refresh `Task` lifecycle, and a `phase` enum
(empty/loading/loaded/error — subsumes `isUpdating`, last-updated, and Reader's not-yet-cached case).
It holds an **injected refresh strategy closure** — never CoreApi/SyncEngine/CloudKit — so `CoreApp`
stays clean. Injected scoped to the detail subtree at navigation time.

Access uses the full house pattern; each layer earns its place:
- **`@[Subject]` property wrapper** (`@Post(\.phase)`) — scoped reactivity (a view re-renders only
  for the keypath it reads) + mandated by `tmbr-app/CLAUDE.md`. ~20 lines; the pattern already
  exists twice (`@Blog`, `@Catalogue`).
- **Refresh as an action** (`RefreshPostAction`) — **this is the three-app seam.** One env key,
  a different body per app (Author → `syncEngine`; Reader → fetch-public-item + upsert; Personal →
  no-op). `EnvironmentValues` can't be generic, so use one concrete key per entity type
  (`refreshPost`, `refreshCatalogueItem`) — matching the existing "one key per action" convention.
  The same shape repeats at list level (`refreshBlog`, `refreshCatalogue`): Reader fetches the public
  list page + upserts; Author runs `syncAll`; Personal no-ops.
- **Atomic controls** (phase indicator, refresh button) — built **lazily**, only when a second
  consumer appears (YAGNI, per `networking.md`'s "add on concrete need").

Heterogeneous catalogue is not a problem: the list observes `PreviewRecord`; a detail model takes the
typed record (e.g. `SongRecord`, fetched by `previewID`) + a refresh strategy that dispatches on
`categoryType` to the right `RequestLoader`. (See the normalized schema section below.)

---

## Schema: normalized, mirroring the backend

Because Author **and** Personal must author catalogue items **offline** (full per-type metadata +
album/playlist track lists), the app needs the typed structure — and the heterogeneous-list problem
is already solved on the backend by the `Preview` projection, so the app mirrors that exactly. (An
earlier flat `CatalogueItemRecord` was considered and **dropped** for this reason.)

- **`PreviewRecord`** — the unified projection (mirrors backend `Preview`): `id` = server PreviewID
  (UUID), `categoryType`, `primaryInfo`/`secondaryInfo`, `imageURL`, `externalLinks`, `accessRaw`,
  `createdAt`/`updatedAt`, `syncStateRaw`. **Drives the heterogeneous list** via one
  `@Query<PreviewRecord>`, and is the **note anchor**. An **orphan** is a `PreviewRecord` with no
  backing typed record (`sourceID == nil` / `isOrphan`).
- **Per-type records** — `SongRecord`, `AlbumRecord`, `BookRecord`, `MovieRecord`, `PodcastRecord`,
  `PlaylistRecord` — rich typed fields for detail + offline authoring, each linked to its Preview by
  `previewID: UUID` (a plain UUID link, **not** a `@Relationship` — matches backend `preview_id`,
  keeps CloudKit mirroring trivial).
- **`ContainerEntryRecord`** — album/playlist member ordering (mirrors backend `ContainerEntry`).
  Track-removal honors promotion: only `.promotable` members are removed when a container is deleted.
- `NoteRecord` (anchored to a Preview by PreviewID), `PostRecord`, `QuoteRecord`, `UserRecord`.
- `AppSchema.models` is the single shared model list; each app builds its own `ModelContainer` from it.

**Reads:** list = `@Query<PreviewRecord>`; detail/edit = fetch the typed record by `previewID`.
**Per app:** Author + Personal author into typed records + Preview; **Reader** stays thin — fills
`PreviewRecord` for the list, lazily caches the typed record when a detail is opened.

**CloudKit constraints still hold** (made now because schema is costly to change post-ship; justified
by Personal) and are unaffected by normalization:

1. **No `@Attribute(.unique)`** — uniqueness lives in the upsert (fetch-by-identity before insert).
2. **Every stored attribute optional or defaulted** (e.g. `var title = ""`). The `@Model` macro needs
   the fully-qualified `Date.now`, not a bare `.now`.
3. **Link by UUID, not `@Relationship`** — `previewID`/`memberPreviewID`/`attachmentPreviewID`. Keeps
   mirroring trivial and lets records exist before their Preview is synced.
4. **`nonisolated` payload structs** — so `NoteInput`/`PostInput`/`NoContent` `Codable` conformances
   are usable as `Sendable` generic arguments to `RequestLoader`.

`syncState`/`serverID`/tombstone fields are used fully by Author, set-but-ignored by Personal, and
effectively always-`.synced` in Reader. One shared schema across all three.

**Status:** the `CoreApp` package + this schema are **built and compiling** (`swift build`).
**Still to validate at runtime (before Personal ships):** that the schema round-trips to a `.private`
CloudKit database.

---

## Project structure

Two repo-root SPM packages (shared with the web side via `core-tmbr`) + three thin app targets:

```
core-tmbr/                      ← module CoreTmbr — shared Codable DTOs (also used by tmbr-web)
core-api/                       ← module CoreApi  — HTTP client + Sync/ (per-endpoint requests,
                                   RequestLoader.syncAll); linked by Reader + Author, NOT Personal
core-app/                       ← module CoreApp  — Persistence/, Blog/, Catalogue/, shared views,
                                   property wrappers, environments, actions, detail models,
                                   DTO→record upsert; SwiftData + CoreTmbr only (no networking)
tmbr-app/
  Author/                       ← @main, ModelContainer, SyncEngine, AuthState, background sync
  Reader/                       ← @main, plain container, read-only UI, fetch+upsert, public APIConfig
  Personal/                     ← @main, .private CloudKit container, CloudKit entitlement, no engine
  Configs/                      ← shared base .xcconfig + per-app overrides (bundle id, entitlements,
                                   APIBaseURL, CloudKit container id)
```

The `core-api` split (formerly `AppBackend`) exists so Personal carries **no** networking code; keeping
Personal backend-free is a deliberate guard.

---

## Backend: kept, not redesigned

The branch's backend is, field-for-field, Author's backend — fully aligned, not a two-product
compromise. Keep as-is: the `core-tmbr` pagination contract; `core-web` pagination infra; per-type list
endpoints; `GET /api/posts` pagination; `GET /api/catalogue/orphans?notes=true`; embedded-notes design;
deletion tombstones; `PreviewResponse.id`; the `NoteModelMiddleware` `updatedAt` bump.

- **Personal needs:** nothing.
- **Reader needs now:** nothing — it runs on the **existing** per-type list + orphan endpoints,
  unauthenticated (public-only scoping below). **Reader optimization (additive, later):** a dedicated
  public read API (browse/feed + per-item detail JSON) and ETag / `If-None-Match` → `304` support.

The optional/soft auth on the list + deletions endpoints (added during the earlier guest-sync
experiment) is **safe and reusable**, not dead weight: the previewable `query` permission scopes
unauthenticated callers to `access == .public` only (authenticated owner → own + public), so guests
never receive private data — which is exactly the access model the Reader app needs.

---

## Build order & deferred

**Building now (Reader first):** the three-target split, the shared UI moved into `CoreApp`, and the
**Reader** app's read path (lazy fetch+upsert of public lists + detail over the existing endpoints).
Reader is the simplest *complete* app — it validates the whole stack before Author's heavier sync.

**Deferred (designed here, not built now):**
- **Reader optimization**: ETag/`304` stale-while-revalidate + a dedicated public read API (per-item
  detail JSON). The first build refetches over the existing endpoints.
- **Author app**: the delta `SyncEngine` (eager `syncAll` + push/pull + tombstones), auth, offline writes.
- **Personal app**: the `.private` CloudKit container wiring and runtime mirror validation.
- **Atomic controls** for the read/refresh detail models — added when a second consumer appears.
- Whether `CoreApi` stays separate or folds into `CoreApp`.
