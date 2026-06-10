# Offline-First Native App: Multi-Stage Roadmap

> **Upon exiting plan mode**: copy this file to `/Users/danieltmbr/Documents/projects/tmbr/.claude/docs/plans/offline-first-native-app.md` as the canonical living document in the repo.

---

## Vision

The end state is a native app that feels fast and reliable regardless of connectivity:

- **Instant startup**: cached SwiftData renders before any network request completes
- **Invisible sync**: delta sync runs in the background; `@Query` in views auto-updates as records arrive
- **Offline writes**: notes and posts saved locally first, pushed silently when online
- **No spinners on launch**: the user always sees their data, never a loading screen

Each stage below is a self-contained PR that ships a working increment. Later stages depend on earlier ones but each leaves the app in a releasable state.

---

## Domain Primer: Catalogue Item Types

The backend has three distinct kinds of catalogue item that the native app must handle:

| Kind | Examples | Backing model | Notes? | How synced |
|------|----------|--------------|--------|------------|
| `.entry` (typed) | Song, Album, Book, Movie, Podcast, Playlist | Yes (SongResponse etc.) | Yes | Per-type list endpoints |
| `.orphan` | Recipe, Guide, Link, user-defined | No | Yes | `GET /api/catalogue?orphanOnly=true` |
| `.promotable` | Track (unresolved) | No | **No** | Not synced — shown as part of album/playlist tracks |

**Critical rule** (from memory): use `kind.isShallow` — not `parentID == nil` — to check whether an item can have notes. Orphans have `parentID == nil` but CAN have notes.

Orphan items are identified in `PreviewResponse` by `category != nil` (only set for orphans) and `source.id == nil`. `PreviewResponse` is their complete data — there is no richer detail endpoint.

---

## Stage 1 — Backend: Shared Pagination Contract + Per-Type List Endpoints

**PR scope**: `tmbr-core` + `tmbr-web`

**Goal**: Establish the reusable pagination types used by every list endpoint. Add all the list endpoints the native app needs for sync. Expose `GET /api/notes` as a Bearer-authenticated endpoint.

### Shared Types (tmbr-core)

```swift
// Query parameters for any paginated endpoint
public struct PageQuery: Codable, Sendable {
    public let since: Date?    // delta sync: items created/modified after this date
    public let cursor: String? // load-more: opaque cursor from the previous Page.nextCursor
    public let limit: Int?     // max items (default 50, max 100)
}

// Standard paginated response wrapper
public struct Page<T: Codable & Sendable>: Codable, Sendable {
    public let items: [T]
    public let hasMore: Bool
    public let nextCursor: String?  // ISO8601 date of last item; nil when hasMore == false
}
```

`since` and `cursor` serve different purposes:
- `since` = "give me everything newer than my last sync" (delta sync, goes forward)
- `cursor` = "give me the next page of older items" (load-more, goes backward)

`nextCursor` is opaque from the client's perspective — the server computes it, the client sends it back as `cursor` on the next request.

### Vapor Convention (tmbr-web)

Shared helpers so all endpoints follow the same pattern:

```swift
// Shared Fluent extension — applies since/cursor/limit, detects hasMore
extension QueryBuilder where Model: Model {
    func paginate(_ query: PageQuery, sortedBy field: KeyPath<...>) async throws -> (results: [Model], hasMore: Bool, nextCursor: String?)
}

// Convenience initializer for building Page<T> response
extension Page {
    init(from paginationResult: ..., mapping transform: ([Model]) -> [T])
}
```

All list handlers follow this pattern:
```swift
let query = try req.query.decode(PageQuery.self)
let (models, hasMore, cursor) = try await Model.query(on: req.db)
    .filter(...)
    .paginate(query, sortedBy: \.$createdAt)
return Page(from: (models, hasMore, cursor)) { $0.map { response($0) } }
```

### New and Updated Endpoints

**Notes (new API endpoint):**
- `GET /api/notes` — Bearer auth — returns `Page<NoteResponse>` for the current user's notes, sorted by `createdAt DESC`. Requires new `Command+ListNotes` command.

**Posts (pagination added):**
- `GET /api/posts` — update to accept `PageQuery`, return `Page<PostResponse>`

**Catalogue (pagination + orphan filter):**
- `GET /api/catalogue` — update to accept `PageQuery`. Add `orphanOnly: Bool?` query param. When `orphanOnly=true`, returns only `.orphan` kind items. The native app uses this filter to sync orphan items separately from typed items.

**Per-type list endpoints (all new):**

| Endpoint | Response | Notes |
|----------|----------|-------|
| `GET /api/songs` | `Page<SongResponse>` | Songs owned by current user |
| `GET /api/albums` | `Page<AlbumResponse>` | Albums owned by current user |
| `GET /api/books` | `Page<BookResponse>` | Books owned by current user |
| `GET /api/movies` | `Page<MovieResponse>` | Movies owned by current user |
| `GET /api/podcasts` | `Page<PodcastResponse>` | Podcasts owned by current user |
| `GET /api/playlists` | `Page<PlaylistResponse>` | Playlists owned by current user |

These return full domain objects (same data as the existing `GET /api/[type]/:id` but as a paginated list). Notes embedded in each response are the current user's notes only.

### Files

| Package | File | Change |
|---------|------|--------|
| tmbr-core | `PageQuery.swift` | NEW |
| tmbr-core | `Page.swift` | NEW |
| tmbr-web | `Shared/Pagination/QueryBuilder+Paginate.swift` | NEW |
| tmbr-web | `Shared/Pagination/Page+Vapor.swift` | NEW |
| tmbr-web | `Notes/Commands/Note/Command+ListNotes.swift` | NEW |
| tmbr-web | `Notes/Commands/Commands+Notes.swift` | add `list` factory |
| tmbr-web | `Notes/Routes/API/NotesAPIController.swift` | add `GET /api/notes` |
| tmbr-web | `Posts/Routes/API/PostsAPIController.swift` | add `PageQuery`, return `Page<>` |
| tmbr-web | `Catalogue/.../CatalogueAPIController.swift` | add `PageQuery` + `orphanOnly` filter |
| tmbr-web | `Catalogue/Song/Routes/API/SongAPIController.swift` | add `GET /api/songs` list route |
| tmbr-web | `Catalogue/Album/Routes/API/AlbumAPIController.swift` | add `GET /api/albums` list route |
| tmbr-web | `Catalogue/Book/Routes/API/BookAPIController.swift` | add `GET /api/books` list route |
| tmbr-web | `Catalogue/Movie/Routes/API/MovieAPIController.swift` | add `GET /api/movies` list route |
| tmbr-web | `Catalogue/Podcast/Routes/API/PodcastAPIController.swift` | add `GET /api/podcasts` list route |
| tmbr-web | `Catalogue/Playlist/Routes/API/PlaylistAPIController.swift` | add `GET /api/playlists` list route |

### Checklist

- [ ] `PageQuery` added to tmbr-core
- [ ] `Page<T>` added to tmbr-core
- [ ] `QueryBuilder+Paginate.swift` — shared Fluent pagination helper
- [ ] `Page+Vapor.swift` — `Page(from:mapping:)` convenience init
- [ ] `Command+ListNotes.swift` + `Commands+Notes.swift` updated
- [ ] `GET /api/notes` with Bearer auth, returns `Page<NoteResponse>`
- [ ] `GET /api/posts` updated to `Page<PostResponse>` with `PageQuery`
- [ ] `GET /api/catalogue` updated with `PageQuery` + `orphanOnly` filter
- [ ] `GET /api/songs` list route (pagination, current user filter)
- [ ] `GET /api/albums` list route
- [ ] `GET /api/books` list route
- [ ] `GET /api/movies` list route
- [ ] `GET /api/podcasts` list route
- [ ] `GET /api/playlists` list route
- [ ] Manual test: `GET /api/notes?limit=5` returns correct `Page<NoteResponse>` shape
- [ ] Manual test: `GET /api/notes?since=<date>` returns only newer notes
- [ ] Manual test: `GET /api/catalogue?orphanOnly=true` returns only orphan items
- [ ] Manual test: `GET /api/songs` returns the current user's songs with full data
- [ ] Existing web frontend unaffected (uses session auth, different middleware path)

---

## Stage 2 — App: Local Persistence Layer

**PR scope**: `tmbr-app` only (no networking, no sync yet)

**Goal**: SwiftData schema in place, `ModelContainer` wired into the app. Lists still show placeholders. This PR gets the local DB right before anything else depends on it.

### SwiftData Schema

All `@Model` files in `tmbr-app/tmbr/Persistence/`.

**SyncState**:
```swift
enum SyncState: String, Codable {
    case synced           // matches server state
    case pendingCreate    // exists locally, not on server yet
    case pendingUpdate    // local version differs from server
    case pendingDelete    // deleted locally, server delete pending
}
```

**NoteRecord**:
```swift
@Model final class NoteRecord {
    @Attribute(.unique) var clientKey: UUID  // always client-generated; stable local identity
    var serverID: UUID?                       // set from NoteResponse.id after first push
    var body: String
    var accessRaw: String                     // Access.rawValue
    var languageRaw: String                   // Language.rawValue
    var createdAt: Date
    var syncState: String

    // Denormalized attachment fields — avoids requiring CatalogueItemRecord to exist first
    var attachmentID: UUID                    // PreviewID of the catalogue item
    var attachmentTitle: String
    var attachmentSubtitle: String?
    var attachmentCategoryType: String?       // e.g. "song", "book", "recipe"
    var attachmentSourceID: Int?              // nil for orphan attachments
}
```

`clientKey` is always client-generated. `serverID` is nil until the backend confirms the create (the backend generates note UUIDs server-side). After push, `NoteResponse.id` is written back to `serverID`.

**PostRecord**:
```swift
@Model final class PostRecord {
    @Attribute(.unique) var clientKey: UUID  // stable local identity
    var serverID: Int?                        // nil until server assigns PostID
    var title: String
    var content: String
    var stateRaw: String                      // PostState.rawValue
    var languageRaw: String
    var createdAt: Date
    var publishedAt: Date?
    var syncState: String
    var attachmentID: UUID?
    var attachmentTitle: String?
}
```

**QuoteRecord**:
```swift
@Model final class QuoteRecord {
    @Attribute(.unique) var clientKey: UUID
    var body: String
    var noteClientKey: UUID                   // links to NoteRecord.clientKey
    var noteServerID: UUID?                   // set once parent note has a serverID
    var sourcePreviewID: UUID
    var sourceTitle: String                   // denormalized title of quoted item
    var sourceType: String?
    var syncState: String
}
```

Server-side dedup key for quotes: `(noteServerID, body)` — QuoteResponse has no server-side ID.

**CatalogueItemRecord + subclasses** (SwiftData inheritance, iOS/macOS 26+):

The base class holds fields common to ALL catalogue items and sufficient for list display. Typed subclasses add semantic named fields for type-specific display and detail views. `OrphanRecord` has no additional fields — `PreviewResponse` is the complete data for orphan items.

The `subtitle` field in the base serves list display for all types. For typed items it is redundant with the subclass field (e.g., `SongRecord.artist`) but enables consistent list rendering without downcasting.

```swift
@Model class CatalogueItemRecord {
    @Attribute(.unique) var id: UUID           // PreviewID (stable cross-type identifier)
    var title: String                          // PreviewResponse.primaryInfo
    var subtitle: String?                      // PreviewResponse.secondaryInfo — used in list display
    var categoryType: String                   // "song"|"album"|"recipe"|etc. (source.type slug)
    var sourceID: Int?                         // type-specific Int ID; nil for orphans
    var imageURL: String?
    var thumbnailURL: String?
    var lastFetchedAt: Date
    var syncState: String

    // Detail-level — nil for orphans (preview IS their full data); nil for typed items until detail sync
    var genre: String?
    var releaseDate: Date?
    var accessRaw: String?
    var detailFetchedAt: Date?
}

// Typed subclasses — semantic named fields, populated from per-type sync responses

@Model final class SongRecord: CatalogueItemRecord {
    var artist: String?          // SongResponse.artist; also set in base.subtitle
    var albumTitle: String?      // SongResponse.album
}

@Model final class AlbumRecord: CatalogueItemRecord {
    var artist: String?          // AlbumResponse.artist; also set in base.subtitle
    var tracksJSON: Data?        // JSON-encoded [TrackItem]
}

@Model final class BookRecord: CatalogueItemRecord {
    var author: String?          // BookResponse.author; also set in base.subtitle
}

@Model final class MovieRecord: CatalogueItemRecord {
    var director: String?        // MovieResponse.director; also set in base.subtitle
}

@Model final class PodcastRecord: CatalogueItemRecord {
    var host: String?            // PodcastResponse host/show; also set in base.subtitle
    var episodeNumber: Int?
    var seasonNumber: Int?
}

@Model final class PlaylistRecord: CatalogueItemRecord {
    var creator: String?         // PlaylistResponse creator; also set in base.subtitle
    var playlistDescription: String?
    var tracksJSON: Data?
}

// Orphan — PreviewResponse IS the complete data; no additional fields needed
// Identified by: sourceID == nil, categoryType = user-defined slug (e.g., "recipe")
@Model final class OrphanRecord: CatalogueItemRecord { }
```

**UserRecord**:
```swift
@Model final class UserRecord {
    @Attribute(.unique) var serverID: Int
    var appleID: String
    var email: String?
    var firstName: String?
    var lastName: String?
}
```

### ModelContainer Setup

In `tmbr.swift`, create the container with all model types registered. `CatalogueItemRecord` must be listed before its subclasses.

### Checklist

- [ ] `SyncState.swift`
- [ ] `NoteRecord.swift`
- [ ] `PostRecord.swift`
- [ ] `QuoteRecord.swift`
- [ ] `CatalogueItemRecord.swift` — base class
- [ ] `SongRecord.swift`, `AlbumRecord.swift`, `BookRecord.swift`, `MovieRecord.swift`, `PodcastRecord.swift`, `PlaylistRecord.swift`, `OrphanRecord.swift`
- [ ] `UserRecord.swift`
- [ ] `tmbr.swift` — create `ModelContainer` with all models; inject via `.modelContainer(container)`
- [ ] App builds and runs on both iOS and macOS targets (placeholders still showing)

---

## Stage 3 — App: Delta Sync + Read-Only Lists

**PR scope**: `tmbr-app` (requires Stage 1 + Stage 2)

**Goal**: App reads real data. Startup shows cached data instantly. Background delta sync keeps it fresh. This is the milestone where the app becomes genuinely useful.

### Startup Flow

```
App opens
  → @Query renders cached SwiftData immediately (no loading state, no spinner)
  → if signed in: Task { await SyncEngine.syncDelta() }
      push any pending local changes (none in read-only stage)
      in parallel:
        GET /api/notes?since=lastSyncAt       → upsert NoteRecord + QuoteRecord
        GET /api/posts?since=lastSyncAt       → upsert PostRecord
        GET /api/songs?since=lastSyncAt       → upsert SongRecord (full domain data)
        GET /api/albums?since=lastSyncAt      → upsert AlbumRecord
        GET /api/books?since=lastSyncAt       → upsert BookRecord
        GET /api/movies?since=lastSyncAt      → upsert MovieRecord
        GET /api/podcasts?since=lastSyncAt    → upsert PodcastRecord
        GET /api/playlists?since=lastSyncAt   → upsert PlaylistRecord
        GET /api/catalogue?orphanOnly=true&since=lastSyncAt → upsert OrphanRecord
      save lastSyncAt = .now to UserDefaults
  → @Query auto-updates as records arrive
```

With `since` filtering, most requests return 0 items on a typical launch — 9 small parallel requests total.

**First launch** (`lastSyncAt == nil`): same flow, `since` omitted → fetches the most recent 50 items per type. Older history loads via `syncFull()` in Stage 5.

### SyncEngine

```swift
@MainActor final class SyncEngine {  // pure service, not @Observable
    func syncDelta() async throws  // fast, parallel, uses since=lastSyncAt
    func syncFull() async throws   // slow, paginated, fetches all history (Stage 5)
    
    // Pull helpers (each paginates to completion)
    private func fetchNotes(since: Date?) async throws
    private func fetchPosts(since: Date?) async throws
    private func fetchTypedItems(since: Date?) async throws  // all 6 types in parallel
    private func fetchOrphans(since: Date?) async throws
    
    // Upsert helpers
    private func upsertNotes(_ responses: [NoteResponse])
    private func upsertPosts(_ responses: [PostResponse])
    private func upsertSongs(_ responses: [SongResponse])
    // ... etc per type
    private func upsertOrphans(_ responses: [PreviewResponse])
}
```

**Upsert logic for typed items**: match on `sourceID + categoryType`. If found and `.synced`, update all fields (including `subtitle` and the semantic subclass field). If not found, create the correct subclass. Notes embedded in type responses (e.g., `SongResponse.notes`) are NOT used here — notes come from the dedicated notes sync which supports delta.

**Upsert logic for orphans**: match on `id` (PreviewID). Orphans get `OrphanRecord`; `subtitle` = `secondaryInfo`.

**Upsert logic for notes**: match on `serverID`. If `.synced`, update fields and sync embedded quotes (match by `noteServerID + body`, delete missing). If `syncState != .synced`, skip body/fields but still sync quotes (they are server-owned). Delete notes with `serverID` and `.synced` state absent from response.

### PageLoader Pattern

A helper that drives pagination for any `Page<T>` endpoint, used inside SyncEngine:

```swift
func fetchAll<T: Decodable & Sendable>(
    loader: RequestLoader<BasicRequest<PageQuery, Page<T>>>,
    since: Date?
) async throws -> [T] {
    var all: [T] = []
    var cursor: String? = nil
    repeat {
        let query = PageQuery(since: all.isEmpty ? since : nil, cursor: cursor, limit: 50)
        let page = try await loader.load(from: query)
        all.append(contentsOf: page.items)
        cursor = page.nextCursor
    } while page.hasMore
    return all
}
```

### BlogModel + CatalogueModel

`@MainActor @Observable final class` — own sync state and write operations. Do NOT hold data arrays; views use `@Query`.

```swift
final class BlogModel {
    private(set) var isSyncing = false
    private(set) var lastSyncedAt: Date?
    private(set) var syncError: Error?
    func sync() async { ... }
}
// Same shape for CatalogueModel
```

### Property Wrappers + Actions + Environment

Follow `.claude/docs/swiftui-architecture.md` exactly:
- `@Blog` property wrapper (KeyPath + ReferenceWritableKeyPath inits)
- `@Catalogue` property wrapper
- `BlogEnvironment.swift` — `@Entry var syncBlog: SyncBlogAction`
- `CatalogueEnvironment.swift` — `@Entry var syncCatalogue: SyncCatalogueAction`
- `View+Blog.swift` — `.blog(_ model:)` injects model + actions
- `View+Catalogue.swift` — `.catalogue(_ model:)` injects model + actions

### Updated Views

```swift
// BlogTab.swift
@Query(sort: \PostRecord.createdAt, order: .reverse) private var posts: [PostRecord]
@Blog(\.isSyncing) private var isSyncing
@Environment(\.syncBlog) private var syncBlog
// body: NavigationStack → List(posts) → .task { await syncBlog() }

// CatalogueTab.swift
@Query(sort: \CatalogueItemRecord.title) private var items: [CatalogueItemRecord]
@Catalogue(\.isSyncing) private var isSyncing
@Environment(\.syncCatalogue) private var syncCatalogue
// body: NavigationStack → List(items) → .task { await syncCatalogue() }
```

### Files to Create

```
tmbr/Sync/
    SyncEngine.swift

tmbr/Blog/
    BlogModel.swift
    BlogEnvironment.swift
    @Blog.swift
    View+Blog.swift
    Actions/SyncBlogAction.swift
    Requests/PostsRequest.swift

tmbr/Catalogue/
    CatalogueModel.swift
    CatalogueEnvironment.swift
    @Catalogue.swift
    View+Catalogue.swift
    Actions/SyncCatalogueAction.swift
    Requests/NotesRequest.swift
    Requests/SongsRequest.swift + AlbumsRequest.swift + ... (one per type)
    Requests/OrphansRequest.swift
```

Modified: `tmbr.swift`, `ContentView.swift`, `BlogTab.swift`, `CatalogueTab.swift`

### Checklist

- [ ] `SyncEngine.swift` — syncDelta, all fetch/upsert helpers
- [ ] `PageLoader` helper (fetchAll pagination loop)
- [ ] Request files for all 9 sync endpoints
- [ ] `BlogModel.swift` + `@Blog.swift` + `BlogEnvironment.swift` + `View+Blog.swift` + `SyncBlogAction.swift`
- [ ] `CatalogueModel.swift` + `@Catalogue.swift` + `CatalogueEnvironment.swift` + `View+Catalogue.swift` + `SyncCatalogueAction.swift`
- [ ] `tmbr.swift` — SyncEngine, BlogModel, CatalogueModel created + injected
- [ ] `ContentView.swift` — `.blog()` + `.catalogue()` modifiers
- [ ] `BlogTab.swift` — `@Query` on PostRecord, `.task { await syncBlog() }`
- [ ] `CatalogueTab.swift` — `@Query` on CatalogueItemRecord, `.task { await syncCatalogue() }`
- [ ] `scenePhase` observer — call both sync methods on `.active`
- [ ] `lastSyncAt` stored in UserDefaults
- [ ] **Test**: create note on web → relaunch app → note appears
- [ ] **Test**: create orphan item on web with note → relaunch → appears in catalogue list
- [ ] **Test**: airplane mode → relaunch → all cached data visible, no blank screens
- [ ] **Test**: delta sync only fetches items newer than lastSyncAt (verify via network proxy)

---

## Stage 4 — App: Offline Writes

**PR scope**: `tmbr-app` (requires Stage 3)

**Goal**: User can create, edit, and delete notes and posts from the app. Changes persist locally first and sync to the backend transparently.

### Write Flow

```
User saves note
  → CreateNoteAction: insert NoteRecord(.pendingCreate) into SwiftData
  → @Query auto-updates list immediately (optimistic UI)
  → Task { try await syncEngine.pushPendingNotes() }
      POST /api/catalogue/item/:previewID/notes
      on success: write NoteResponse.id → NoteRecord.serverID, set .synced
      on failure: leave as .pendingCreate, retry on next sync cycle
```

### Push Logic in SyncEngine

```swift
func pushPendingNotes() async throws {
    // FetchDescriptor<NoteRecord> where syncState != "synced"
    // .pendingCreate → POST, write back serverID
    // .pendingUpdate → PUT /api/notes/:serverID
    // .pendingDelete → DELETE /api/notes/:serverID, then modelContext.delete(record)
}
func pushPendingPosts() async throws { /* same pattern */ }
```

`runSync()` always pushes first, then pulls (preserves offline writes):
```swift
func runSync() async throws {
    try await pushPendingPosts()
    try await pushPendingNotes()
    try await syncDelta()
}
```

### Actions Added

- `CreateNoteAction`, `UpdateNoteAction`, `DeleteNoteAction`
- `CreatePostAction`, `UpdatePostAction`, `DeletePostAction`
- `CatalogueEnvironment` and `BlogEnvironment` updated with new keys

### Checklist

- [ ] `CreateNoteAction.swift` + `UpdateNoteAction.swift` + `DeleteNoteAction.swift`
- [ ] `CreatePostAction.swift` + `UpdatePostAction.swift` + `DeletePostAction.swift`
- [ ] `SyncEngine.pushPendingNotes()` + `pushPendingPosts()`
- [ ] `SyncEngine.runSync()` — push first, then syncDelta
- [ ] Environments + injection modifiers updated with new action keys
- [ ] `BlogEditorView` — basic text entry wired to CreatePostAction / UpdatePostAction
- [ ] `NoteEditorView` — basic text entry wired to CreateNoteAction / UpdateNoteAction
- [ ] Pending sync indicator on list rows (`syncState != "synced"`)
- [ ] **Test**: create note in app → kill app → relaunch → note visible
- [ ] **Test**: create note offline → restore connectivity → syncs to web
- [ ] **Test**: delete note → removed from SwiftData immediately → server delete syncs
- [ ] **Test**: edit note offline → persists after relaunch → syncs when online

---

## Stage 5 — App: Polish + Background Sync + Load More

**PR scope**: `tmbr-app` (requires Stage 4)

**Goal**: The app feels complete and native. Background sync, infinite scroll, full sync option, offline indicator, retry UI.

### Features

- **Background Sync** (`BGAppRefreshTask`): `syncDelta()` runs while app is backgrounded
- **Infinite scroll**: load-more at list bottom uses `cursor` parameter, appends to SwiftData
- **Full Sync in Settings**: calls `SyncEngine.syncFull()` with progress indicator
- **Network-aware push**: `NWPathMonitor` → on connectivity restore, immediately drain pending queue
- **Pull-to-refresh**: `.refreshable` on Blog and Catalogue lists
- **Sync error UI**: retry banner when `BlogModel.syncError` / `CatalogueModel.syncError` is set
- **Offline indicator**: subtle status when `NWPathMonitor` reports no connectivity

### Checklist

- [ ] `Info.plist` — register background fetch task identifier
- [ ] `tmbr.swift` — schedule `BGAppRefreshTask`, implement handler
- [ ] `NetworkMonitor.swift` — `@Observable` NWPathMonitor wrapper
- [ ] `SyncEngine.syncFull()` — paginated full history fetch per type
- [ ] `SyncEngine.fetchOlderPosts(before:)` + `fetchOlderCatalogueItems(before:)` (load-more)
- [ ] `LoadMorePostsAction.swift` + `LoadMoreCatalogueItemsAction.swift`
- [ ] `BlogTab.swift` — load-more trigger + `.refreshable`
- [ ] `CatalogueTab.swift` — load-more trigger + `.refreshable`
- [ ] `AccountSheet.swift` — "Full Sync" button + progress indicator
- [ ] Sync error banner with retry in Blog and Catalogue tabs
- [ ] Offline status indicator in UI
- [ ] **Test**: background fetch triggers without opening app
- [ ] **Test**: infinite scroll loads older items
- [ ] **Test**: go offline → create note → go online → network monitor triggers immediate push
- [ ] **Test**: full sync from settings loads all historical data

---

## Cross-Cutting Invariants

**Data flow** (enforced across all stages):
- Reads: SwiftData → `@Query` → View. Network responses never reach views directly.
- Writes: View → Action → SwiftData → SyncEngine push. Server never sees a write that wasn't committed locally first.

**Conflict resolution**: last-write-wins. Server response overwrites `.synced` local records during pull. Records with `syncState != .synced` are preserved until pushed.

**Catalogue item identity**:
- Typed items: identified by `(categoryType, sourceID)` — the type slug + the Int ID
- Orphan items: identified by `id` (PreviewID UUID) — no backing model ID

**SwiftData concurrency**: all operations on `@MainActor` via `container.mainContext`. Volume doesn't justify background contexts.

**tmbr-core discipline**: any type shared between backend and app (including `PageQuery`, `Page<T>`) goes into tmbr-core before implementation.
