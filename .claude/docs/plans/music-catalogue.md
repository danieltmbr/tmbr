# Music Catalogue — Architecture & Feature Design Reference

> This document captures the full design discussion for extending the catalogue beyond Songs to include Albums and Playlists. It covers mental models we evaluated, the decisions we made, the data model, and the user-facing UX concepts. Intended as a durable reference across implementation sessions.

---

## Implementation Progress

| Stage | Description | Status |
|-------|-------------|--------|
| Pre | Generalisation pass — unified list/editor/detail templates, JS factory | ✅ |
| 1 | Album — model + migration + basic CRUD + metadata autofill | ✅ |
| 2 | Album — ContainerEntry tracklist + display + track auto-promotion | ✅ |
| 3 | Album — Apple Music JSON-LD tracklist import on create | ✅ |
| 4 | Playlist — model + basic CRUD (shell) | ✅ |
| 5 | Playlist — ContainerEntry track management + Apple Music import | ✅ |
| 6 | Unified Music list page and API (`/music`) | ✅ |
| 7 | Unified "New Music" editor (`/music/new`) | ✅ |
| 8 | "Music" catalogue filter (virtual chip) | ✅ |

---

## What Was Built (Stages Pre–4)

### Generalisation pass (PR #152)
Before implementing album tracklists, a cleanup pass unified all 5 existing catalogue types:
- `CatalogueListViewModel` — single shared list ViewModel replaces 5 identical structs
- `Catalogue/list.leaf` — single list template for all types
- `Catalogue/editor.leaf` — single base editor template; each type extends it with `editor-fields`, `editor-title-input`, `editor-preview-form`, `editor-type-script`
- `Catalogue/details.leaf` — pure frame; each type exports `detail-header` and `detail-body`
- `CatalogueEditorController.init(config)` in `catalogue-editor.js` — JS factory that accepts a config object; per-type JS files are now ~10 lines each
- Book/Movie renamed `artwork` → `cover` in their ViewModels and leaf files (they own their own templates)

### Stage 1 (PR before #152 — already complete)
Full Album module: model, migrations, CRUD commands, API, web routes, all views, Apple Music metadata autofill.

### Stage 2 (PR #153)
Instead of a dedicated `AlbumTrack` model, a generic `ContainerEntry` join table was introduced. See [Data Model](#data-model) below. Also implemented:
- `ExtendPreview` migration — makes `Preview.parentID` nullable (orphan tracks have `parentType = "track"`, `parentID = nil`)
- `CreateContainerEntries` migration — new `container_entries` table
- `ContainerEntry` Fluent model
- Album detail page fetches entries via `ContainerEntriesInput(containerType: "album", containerID:)` and renders a tracklist
- `GET /catalogue/item/:id` — shallow detail page for orphan Previews (no backing model yet)
- `POST /songs/promote` — auto-promotes an orphan track: reads `previewID`, creates a Song that adopts the orphan Preview's UUID (Preview's `parentType`/`parentID` are updated; ContainerEntry row is untouched)

### Stage 3 (PR #154)
Apple Music JSON-LD tracklist import on album create:
- `HTMLMetadataParser.parseJSONLD` updated to handle multiple named `<script type="application/ld+json">` blocks, keyed by their `id` attribute
- `MetadataExtractor.appleMusicAlbum` reads `metadata.json["schema:music-album"]` for `tracks[]` and `byArtist[]`
- `AlbumMetadata` gains `tracks: [TrackMetadata]?`
- `AlbumEditorPayload` decodes a hidden `tracklist-json` field populated by JS from the metadata response
- `AlbumsWebController` calls `commands.previews.importTracks(ImportAlbumTracksInput(...))` on create — creates one orphan Preview + one ContainerEntry per track
- Update path skips tracklist import to protect already-promoted songs

### Stage 4 (PR #155)
Full Playlist shell — mirrors the Album module but without `artist`, `releaseDate`, metadata/lookup commands, or tracklist. Playlist can have a `description`. `Playlist.previewType = "playlist"` added to `CatalogueQueryMapper`.

---

## Data Model

### Song (unchanged)
```
songs:
  id             Int (PK, auto)
  title          String
  artist         String
  album          String?   ← plain string metadata from Apple Music, NOT a FK
  genre          String?
  release_date   Date?
  access         Access
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

### Album
```
albums:
  id             Int (PK, auto)
  title          String
  artist         String
  release_date   Date?
  genre          String?
  access         Access
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

### Playlist
```
playlists:
  id             Int (PK, auto)
  title          String
  description    String?
  access         Access
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

### ContainerEntry (replaces AlbumTrack and PlaylistEntry)
```
container_entries:
  id              UUID (PK)
  container_type  String    ← "album" | "playlist"
  container_id    Int       ← album.id or playlist.id
  preview_id      UUID FK → previews (cascade)
  position        Int
  UNIQUE (container_type, container_id, preview_id)
```

Querying a container's tracks:
```swift
ContainerEntry.query(on: db)
    .filter(\.$containerType == "album")
    .filter(\.$containerID == albumID)
    .sort(\.$position)
    .with(\.$preview)
    .all()
```

### Preview (modified)
`parentID` is now nullable. Orphan tracks have:
- `parentType = "track"`
- `parentID = nil`
- `primaryInfo` = track name
- `secondaryInfo` = "by \(artist)"
- `externalLinks` = [trackURL] if available

A ContainerEntry pointing to an orphan Preview renders as a promotable track. A ContainerEntry pointing to a Preview with `parentType = "song"` renders as a link to `/songs/:parentID`.

---

## The Track Promotion Pattern (implemented)

When a user taps an unlinked track on an album/playlist detail page:

**Route**: `POST /songs/promote`

1. Read `previewID` from form body
2. Load the orphan Preview
3. Build a `SongInput` from Preview fields (`primaryInfo` → title, `externalLinks` → resourceURLs)
4. Run `CreateSongCommand` with `song.previewID = previewID` (adoption — Song takes over the orphan Preview's UUID)
5. `PreviewModelMiddleware` updates the Preview's `parentType`, `parentID`, `primaryInfo`, `secondaryInfo`
6. Redirect to `/songs/<song.id>`

The ContainerEntry row is never touched — the promoted Song's Preview still carries its album/playlist membership.

**Album/Playlist detail page tracklist rendering**:
- `entry.preview.parentID != nil` → link to `/songs/:parentID`
- `entry.preview.parentID == nil` → promotion form with POST to `/songs/promote`

---

## Remaining Stages

### Stage 5 — Playlist track management + Apple Music import

Playlists currently have no tracklist. This stage adds it using the same ContainerEntry machinery already in place for albums.

**Track management** (user-curated playlists):
Unlike albums where the tracklist comes from Apple Music import, playlist tracks can also be added manually by linking an existing Song. Two entry paths:
1. **Import from Apple Music URL** — same flow as albums: paste a playlist URL, metadata fetch returns tracks, hidden field stores JSON, `PlaylistsWebController` creates orphan Previews + ContainerEntry rows on create
2. **Manual add** (future, not this stage) — search for an existing Song and add it; deferred

**Apple Music playlist import**:
- Apple Music playlists embed JSON-LD with `og:type = "music.playlist"` — confirm the schema; likely similar to albums
- Add `PlaylistMetadata` fields: `title`, `description`, `artwork`, `tracks: [TrackMetadata]?`
- Add `FetchPlaylistMetadataCommand` + `MetadataExtractor.appleMusicPlaylist`
- Add `metadata` command to `Commands.Playlists`
- Add `GET /playlists/metadata` route
- Update `playlist-editor.js` to call the metadata endpoint on URL paste
- Update `PlaylistEditorPayload` to decode `tracklist-json`
- Update `PlaylistsWebController.create` to call `importTracks` with `containerType = "playlist"`
- `Page+Playlist.swift` — fetch ContainerEntry rows, render tracklist in `playlist.leaf`

**Files to create/modify**:
| Action | File |
|--------|------|
| CREATE | `Platform/Metadata/PlaylistMetadata.swift` (expand — add tracks field) |
| CREATE | `Playlists/Commands/Command/FetchPlaylistMetadataCommand.swift` |
| CREATE | `Platform/Extractors/MetadataExtractor+AppleMusicPlaylist.swift` |
| MODIFY | `Playlists/Commands/Commands+Playlists.swift` (add metadata command) |
| MODIFY | `Playlists/Routes/Web/PlaylistsWebController.swift` (metadata route + importTracks on create) |
| MODIFY | `Playlists/Routes/Web/PlaylistEditorPayload.swift` (add tracklistJSONRaw) |
| MODIFY | `Playlists/Routes/Web/Pages/Page+Playlist.swift` (fetch ContainerEntry rows, pass to ViewModel) |
| MODIFY | `Resources/Views/Catalogue/Playlists/playlist.leaf` (add tracklist section) |
| MODIFY | `Public/Scripts/Catalogue/Playlists/playlist-editor.js` (metadata endpoint + onMetadata callback) |

---

### Stage 6 — Unified Music list page and API (`/music`)

A single `/music` page that shows Songs, Albums, and Playlists interleaved in one feed (most recently created first). Also a `/api/music` endpoint.

**Backend**:
- `Command+MusicSearch.swift` — queries Previews filtered to `parentType IN ("song", "album", "playlist")`, joins all three tables for search term matching, returns `MusicSearchResult`
- `Commands+Music.swift` — `Commands.Music` collection with a `search` command
- `MusicWebController` — `GET /music` page
- `MusicAPIController` — `GET /api/music` endpoint
- `Page+Music.swift` — reuses `CatalogueListViewModel` + `Template(name: "Catalogue/list")`

**Modified files**:
- `Catalogue.swift` — register Music module

---

### Stage 7 — Unified "New Music" editor (`/music/new`)

A single entry point for creating any music item. The form starts with just a URL field. When a URL is pasted, the backend detects the type and returns metadata + a `musicType` discriminator. The form morphs to show the appropriate fields.

**Type detection endpoint**: `GET /music/metadata?url=...`
- Returns `{ musicType: "song" | "album" | "playlist", ...metadata fields }`
- Reuses existing per-type metadata extractors; adds `musicType` field to the response

**Form behaviour** (JS):
1. User pastes a URL → call `/music/metadata?url=...`
2. Response includes `musicType` → show the matching field set (artist+genre+releaseDate for song/album; description for playlist)
3. If no URL or ambiguous → show a manual type selector (radio/segmented control)
4. On submit → POST to the type-specific endpoint (`/songs`, `/albums`, `/playlists`)

**Files to create**:
| File | Purpose |
|------|---------|
| `Music/MusicWebController.swift` | `GET /music` + `GET /music/new` + `GET /music/metadata` |
| `Music/MusicAPIController.swift` | `GET /api/music` |
| `Music/Commands/Command+MusicSearch.swift` | Cross-type search |
| `Music/Commands/Commands+Music.swift` | Music command collection |
| `Music/Routes/Web/Pages/Page+Music.swift` | List page context |
| `Music/Routes/Web/Pages/Page+MusicEditor.swift` | New music editor context |
| `Resources/Views/Catalogue/Music/music-editor.leaf` | Unified editor template |
| `Public/Scripts/Catalogue/Music/music-editor.js` | Type detection + form morphing |

**Register in `Catalogue.swift`**.

---

### Stage 8 — "Music" catalogue filter (virtual chip)

The catalogue filter UI shows a single **"Music"** chip that maps to all three music types.

**Backend** (`CatalogueQueryMapper`):
```swift
private static let virtualTypes: [String: Set<String>] = [
    "music": ["song", "album", "playlist"]
]

private func filter(types: Set<String>?) -> Set<String> {
    guard let types else { return allowedTypes }
    let expanded = types.flatMap { virtualTypes[$0] ?? [$0] }
    return allowedTypes.filter { expanded.contains($0) }
}
```

**Frontend** — catalogue filter UI sends `type=music` in the query string; the mapper expands it server-side.

**Files to modify**:
- `CatalogueQueryMapper.swift`
- Catalogue filter leaf/JS (wherever the filter chips are rendered)

---

## Background & Problem Statement

The Song editor feature is near-complete. Before shipping it, we needed to ensure the data model scales to Albums and Playlists without requiring a Song migration later.

**Core tensions we identified**:
1. Albums, Playlists, and Songs all feel like "Music" to the user — but they have meaningfully different fields and relationships
2. Albums and Playlists both "contain songs" — but their containment semantics differ (Albums are published works; Playlists are user-curated)
3. We don't want to expose Song/Album/Playlist as distinct concepts in the UI — the user just thinks "Music"

---

## Mental Models We Evaluated

### Mental Model 1: Single "Music" type with a discriminator enum
One `music` table. A `type` enum column: `song`, `album`, `playlist`. Self-referential relationship for tracklists.

**Why we rejected it**:
- Fields are highly conditional on type: `artist` and `releaseDate` don't apply to playlists; playlists have no tracklist; songs have an album reference
- Self-referential containment (`music → music[]`) is awkward — only valid when parent is album/playlist, never when parent is song
- Violates the clean, type-per-table pattern already established for Books, Movies, Podcasts, Songs

### Mental Model 2: Song + MusicCollection (album/playlist discriminator)
Two models: `Song` and `MusicCollection`. `MusicCollection.type` enum: `album` or `playlist`.

**Why we rejected it**:
- Album and Playlist have genuinely different fields — grouping them creates the same nullable-field problem
- "MusicCollection" is an awkward name; the split between Song and Collection feels artificial when both are "Music" to the user

### Mental Model 3: AlbumTrack / PlaylistEntry as dedicated join models
Separate `album_tracks` and `playlist_entries` tables, each with a nullable `song_id` FK.

**Why we moved away from it**:
- Both tables were structurally identical except for the parent FK column
- A generic `ContainerEntry` (`container_type` + `container_id` + `preview_id` + `position`) serves both without any schema duplication
- ContainerEntry membership survives promotion unchanged — the link doesn't need updating when a Song is created; the Preview's `parentID` update is sufficient

### ✅ Chosen Approach: Three Separate Previewable Types + ContainerEntry
**Song** (existing), **Album** (new), **Playlist** (new) — each a standalone module under `Catalogue/`.

Tracks/entries are represented as orphan `Preview` objects (`parentType = "track"`, `parentID = nil`) linked to their container via `ContainerEntry`. Promotion creates a Song that adopts the orphan Preview's UUID — the ContainerEntry row is never modified.

---

## Metadata Fetching

### Albums (implemented — Stage 3)
Apple Music album pages embed `<script id="schema:music-album" type="application/ld+json">` with the full tracklist. `HTMLMetadataParser.parseJSONLD` was updated to key named JSON-LD blocks by their `id` attribute. `MetadataExtractor.appleMusicAlbum` reads this block for `tracks[]` and `byArtist[]`.

### Playlists (Stage 5)
Apple Music playlist pages likely embed a similar JSON-LD block. Confirm the schema on a real playlist URL, then implement `MetadataExtractor.appleMusicPlaylist` following the same pattern.

---

## UI Notes

- Album detail info line: `genre · release year`
- Song detail info line: `album name · genre · release year`
- Playlist detail: description below title; no artist or release date
- Tracklist rendering (album and playlist detail): promoted tracks link to `/songs/:id`; orphan tracks show a promote button (`POST /songs/promote`)
- Unified Music editor (`/music/new`): starts as a URL-only form; morphs based on detected `musicType`
