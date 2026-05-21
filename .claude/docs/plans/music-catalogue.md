# Music Catalogue — Architecture & Feature Design Reference

> This document captures the full design discussion for extending the catalogue beyond Songs to include Albums and Playlists. It covers mental models we evaluated, the decisions we made, the data model, and the user-facing UX concepts. Intended as a durable reference across implementation sessions.

---

## Implementation Progress

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Album — model + migration + basic CRUD + metadata autofill | ✅ |
| 2 | Album — AlbumTrack model + tracklist display | ⬜ |
| 3 | Album — lazy track promotion (`?track=` param) | ⬜ |
| 4 | Album — Apple Music metadata fetch + tracklist import | ⬜ |
| 5 | Playlist — model + PlaylistEntry + basic CRUD | ⬜ |
| 6 | Playlist — Apple Music metadata fetch | ⬜ |
| 7 | Unified Music list page and API (`/music`) | ⬜ |
| 8 | Unified "New Music" editor (`/music/new`) | ⬜ |
| 9 | "Music" catalogue filter (virtual chip) | ⬜ |

### Stage 1 checklist (✅ complete)
- [x] `Album.swift` model (`previewType = "album"`)
- [x] `CreateAlbum.swift` migration
- [x] `AlbumInput.swift` — input + `ModelConfiguration` + `Validator`
- [x] `CreateAlbumCommand.swift`, `EditAlbumCommand.swift`, `FetchAlbumCommand.swift`
- [x] `Command+AlbumSearch.swift` — joins Preview + Album, searches title/artist/genre
- [x] `Command+LookupAlbum.swift` — duplicate detection by URL
- [x] `Commands+Albums.swift` — command collection
- [x] `AlbumPayload.swift` — API payload
- [x] `Permissions+Albums.swift`
- [x] `AlbumResponse.swift`, `AlbumsAPIController.swift`
- [x] `AlbumEditorPayload.swift`, `AlbumsWebController.swift`
- [x] `Page+Album.swift`, `Page+Albums.swift`, `Page+AlbumEditor.swift`
- [x] `Albums.swift` — module entry
- [x] `albums.leaf`, `album.leaf`, `album-editor.leaf`
- [x] `album-editor.js` — metadata autofill added (fetches `/albums/metadata` on URL insert)
- [x] `FetchAlbumMetadataCommand.swift` + `MetadataExtractor+AppleMusicAlbum.swift` + `Platform+AlbumMetadata.swift`
- [x] Register `.albums` in `Catalogue.swift`
- [x] Add `Album.previewType` to `CatalogueQueryMapper.catalogueTypes`

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

### ✅ Chosen Approach: Three Separate Previewable Types
**Song** (existing), **Album** (new), **Playlist** (new) — each a standalone module under `Catalogue/`.

**Why this is correct**:
- Matches the existing architecture exactly: Books, Movies, Podcasts, Songs are all independent types with their own tables
- No nullable conditional fields — each model only has the fields it needs
- The `Preview` model already handles cross-type queries polymorphically via `parentType`, so three types appear seamlessly in search/feeds
- Adding a new type is well-defined: copy the existing module structure, implement Previewable, register in Catalogue.swift

---

## Data Model

### Song (no changes to existing model)
```
songs:
  id             Int (PK, auto)
  title          String (required)
  artist         String (required)
  album          String? ← stays as plain string metadata, NOT a FK to albums
  genre          String?
  release_date   Date?
  access         Access enum
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

The `album` string field on Song is intentional. It stores album metadata from the song's perspective (exactly as Apple Music returns it). It does NOT become a FK to the `albums` table. A Song doesn't need to know about an Album model — the relationship is owned by the join model (`AlbumTrack`).

### Album (new)
```
albums:
  id             Int (PK, auto)
  title          String (required)
  artist         String (required)
  release_date   Date?
  genre          String?
  access         Access enum
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

### AlbumTrack (child of Album — NOT Previewable)
```
album_tracks:
  id             Int (PK, auto)
  album_id       FK → albums (cascade)
  track_number   Int
  name           String  ← always stored (even if song_id is set)
  song_id        Int?    FK → songs (setNull) ← nil until promoted
```

### Playlist (new)
```
playlists:
  id             Int (PK, auto)
  title          String (required)
  description    String?
  access         Access enum
  owner_id       FK → users (cascade)
  artwork_id     FK → images (setNull)
  preview_id     FK → previews (cascade)
  resource_urls  [String]
  post_id        FK → posts (setNull)
```

### PlaylistEntry (child of Playlist — NOT Previewable)
```
playlist_entries:
  id             Int (PK, auto)
  playlist_id    FK → playlists (cascade)
  position       Int
  name           String  ← always stored
  song_id        Int?    FK → songs (setNull) ← nil until promoted
```

---

## The Lazy Track Promotion Pattern

**Core idea**: When a user imports an Album or Playlist (e.g. from Apple Music), the tracks are stored as lightweight string metadata (`AlbumTrack.name` / `PlaylistEntry.name`). No Song entities are created. A track becomes a proper Song catalogue entry only when the user actively engages with it.

### Promotion flow

**Album/Playlist detail page renders a tracklist**:
- Track has `song_id` set → render as link to Song detail page (`/songs/:id`)
- Track has `song_id` nil → render as link to Song editor (`/songs/new?track=<track_id>`)

**Song editor opened from a track context**:
- Reads the `track` query parameter
- Pre-fills `title` with track name, `album` with the album's title, copies album artwork, etc.
- On save: CreateSongCommand creates the Song entity, then links `AlbumTrack.song_id` (or `PlaylistEntry.song_id`) back to the new Song ID

**Next time the user views the album**: that track is now a link to the Song detail page — no more editor link.

**Key benefit**: Zero friction to import an album. Zero obligation to catalogue every track. The user catalogues only what they care about, naturally, by interacting with tracks.

---

## User-Facing Abstraction: "Music" as a Single Concept

From the user's perspective, Song/Album/Playlist is an implementation detail. The surface-level concept is just **Music**.

### Catalogue Filter

The filter UI shows a single **"Music"** chip, not three separate Song/Album/Playlist options.

Internally, selecting "Music" maps to `parentType IN ('song', 'album', 'playlist')` in the Preview query. The `CatalogueQueryMapper.filter()` expands a virtual `"music"` type string to all three concrete types before intersecting with allowed types.

### Unified "New Music" Entry Point

The compose UI has a single **"New Music"** action, not three separate buttons. Entry point: `GET /music/new`.

**Type detection flow**:
1. User lands on the music editor — sees a URL input field (same UX as the current song editor's resource URL field)
2. User pastes a URL (Apple Music song / Apple Music album / etc.)
3. The JS controller calls the metadata detection endpoint
4. Backend returns metadata + a resolved `musicType: "song" | "album" | "playlist"` field
5. The form morphs to display the appropriate fields for the detected type
6. If no URL is pasted (or URL is ambiguous), a manual type selector is shown

**On submit**: POSTs to the type-specific REST endpoint (`/songs`, `/albums`, `/playlists`) based on the resolved type. The unification is a frontend concern only — the backend stays RESTful and type-specific.

**Deep-link routes stay unchanged**: `/songs/:id`, `/albums/:id`, `/playlists/:id` remain valid for direct linking, API access, and the lazy track promotion flow.

---

## New Module Structure (when implementing)

Following the established pattern (Books, Movies, Podcasts, Songs):

```
Sources/App/Modules/Catalogue/
├── Albums/
│   ├── Albums.swift                         # Module entry: migrations, middleware, routes
│   ├── Models/
│   │   ├── Album.swift                      # Previewable
│   │   ├── AlbumTrack.swift                 # Child model (NOT Previewable) — Stage 2
│   │   └── Migrations/
│   │       ├── CreateAlbum.swift
│   │       └── CreateAlbumTrack.swift       # Stage 2
│   ├── Commands/
│   │   ├── Commands+Albums.swift
│   │   └── Command/
│   │       ├── AlbumInput.swift
│   │       ├── CreateAlbumCommand.swift
│   │       ├── EditAlbumCommand.swift
│   │       ├── FetchAlbumCommand.swift
│   │       ├── Command+AlbumSearch.swift
│   │       ├── Command+LookupAlbum.swift
│   │       └── FetchAlbumMetadataCommand.swift  # ✅ Stage 1
│   ├── Payloads/
│   │   └── AlbumPayload.swift
│   ├── Permissions/
│   │   └── Permissions+Albums.swift
│   └── Routes/
│       ├── API/
│       │   ├── AlbumsAPIController.swift
│       │   └── Responses/AlbumResponse.swift
│       └── Web/
│           ├── AlbumsWebController.swift
│           ├── AlbumEditorPayload.swift
│           └── Pages/
│               ├── Page+Album.swift
│               ├── Page+AlbumEditor.swift
│               └── Page+Albums.swift
│
├── Playlists/                               # Stage 5 — same structure, no metadata fetch command
│   └── ...
│
├── Music/                                   # Stage 8 — unified entry point
│   └── Routes/Web/
│       └── MusicWebController.swift         # GET /music/new → unified editor
│
└── Catalogue/
    └── Commands/
        └── Command+CatalogueSearch.swift    # Stage 9 — expand "music" virtual type
```

**New Leaf templates**:
```
Resources/Views/Catalogue/Albums/album.leaf
Resources/Views/Catalogue/Albums/album-editor.leaf
Resources/Views/Catalogue/Albums/albums.leaf
Resources/Views/Catalogue/Playlists/playlist.leaf       # Stage 5
Resources/Views/Catalogue/Playlists/playlist-editor.leaf # Stage 5
Resources/Views/Catalogue/Playlists/playlists.leaf       # Stage 5
Resources/Views/Catalogue/Music/music-editor.leaf        # Stage 8
```

**Modified files**:
- `Sources/App/Modules/Catalogue/Catalogue.swift` — register Album (Stage 1), Playlist (Stage 5), Music (Stage 8)
- `Sources/App/Modules/Catalogue/Catalogue/Routes/CatalogueQueryMapper.swift` — add Album+Playlist types (Stage 1+5); expand "music" virtual type (Stage 9)
- `Sources/App/Modules/Catalogue/Songs/Routes/Web/SongsWebController.swift` — handle `?track=` context (Stage 3)

---

## Metadata Fetching for Albums (Stage 4)

Platform focus: **Apple Music** (primary). Spotify secondary if needed.

Apple Music URL patterns:
- Song: `https://music.apple.com/us/album/name/id?i=trackID` — `og:type = "music.song"`
- Album: `https://music.apple.com/us/album/name/id` — `og:type = "music.album"`

The Apple Music checker (`PlatformChecker.appleMusic`) already matches both. The extractor gates on `og:type`:
- Existing `MetadataExtractor.appleMusicSong` gates on `"music.song"`
- `MetadataExtractor.appleMusicAlbum` (already implemented for basic fields) gates on `"music.album"`

**Tracklist source (confirmed)**: The Apple Music album page embeds a `<script id="schema:music-album" type="application/ld+json">` block. A single page fetch is sufficient — no extra API or per-track requests needed.

JSON-LD schema (`Metadata.json["schema:music-album"]`):
```json
{
  "@type": "MusicAlbum",
  "name": "...",
  "byArtist": [{ "@type": "MusicGroup", "name": "gyuris" }],
  "datePublished": "2026-05-14",
  "genre": ["Hip-Hop/Rap", "Music"],
  "tracks": [
    { "@type": "MusicRecording", "name": "intro", "duration": "PT3M6S", "url": "https://music.apple.com/gb/song/intro/6768228102" },
    ...
  ]
}
```

Stage 4 work:
- Add `TrackMetadata` type + `tracks: [TrackMetadata]?` to `AlbumMetadata`
- Update `MetadataExtractor.appleMusicAlbum` to parse `Metadata.json["schema:music-album"]` for `tracks[]` + use `byArtist[0].name` as fallback artist (avoids extra `music:musician` fetch)
- Update `CreateAlbumCommand` to insert `AlbumTrack` rows (all `song_id = nil`)

`FetchAlbumMetadataCommand` returns `AlbumMetadata(title, artist, releaseDate, artwork, tracks: [TrackMetadata])`.
`CreateAlbumCommand` creates the Album + `AlbumTrack` rows (all with `song_id = nil`).

---

## Open Decision: Track-to-Song Linking Implementation (Stage 3)

When `GET /songs/new?track=42` is hit, two options for handling the link-back on save:

**Option A**: `SongsWebController` handles everything — reads the `track` param, pre-fills the ViewModel, and on POST: runs `CreateSongCommand` then updates `AlbumTrack.song_id`.

**Option B**: A separate route `POST /albums/:albumID/tracks/:trackID/promote` that owns the linking logic.

Option A is simpler and reuses the existing song editor. Option B is cleaner separation of concerns. Decide at implementation time — likely Option A first, refactor if it gets messy.

---

## UI Notes

- Album detail info line: `genre · release year` (no parent "album" field — Album is the top-level entity)
- Song detail info line unchanged: `album name · genre · release year`
- Album editor: title, artist, genre, release date, artwork, resource URLs, notes (no metadata autofill until Stage 4)
