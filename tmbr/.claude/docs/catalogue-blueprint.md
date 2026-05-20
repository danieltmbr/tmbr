# Catalogue Item Blueprint

Implementation guide for Books, Movies, and Podcasts — based on the completed Songs module.

## Status at a glance

| Layer | Songs | Books | Movies | Podcasts |
|---|---|---|---|---|
| Model + migration | ✅ | ✅ | ✅ | ✅ |
| Commands (CRUD) | ✅ | ✅ | ✅ | ✅ |
| Commands (lookup, search, metadata) | ✅ | ❌ | ❌ | ❌ |
| Permissions | ✅ | ✅ | ✅ | ✅ |
| API payload | ✅ | ✅ | ✅ | ✅ |
| API response DTO | ✅ | ✅ | ✅ | ✅ |
| API controller | ✅ | ❌ | ❌ | ❌ |
| Editor payload (web) | ✅ | ❌ | ❌ | ❌ |
| Web controller | ✅ | ❌ | ❌ | ❌ |
| Page: list view model | ✅ | ❌ | ❌ | ❌ |
| Page: detail view model | ✅ | ✅ | ✅ | ✅ |
| Page: editor view model | ✅ | ❌ | ❌ | ❌ |
| Page: preview view model | ✅ | ❌ | ❌ | ❌ |
| Module boot (routes registered) | ✅ | ❌ | ❌ | ❌ |
| Leaf: list template | ✅ | ❌ | ❌ | ❌ |
| Leaf: editor template | ✅ | ❌ | ❌ | ❌ |
| Platform metadata struct | ✅ | ❌ | ❌ | ❌ |
| Platform extractors | ✅ | ❌ | ❌ | ❌ |
| Editor JS | ✅ | ❌ | ❌ | ❌ |

---

## Implementation order (per type)

Follow this order within each type. Later layers depend on earlier ones.

1. Platform metadata struct + extractors
2. Commands extension (lookup, search, metadata)
3. Editor payload
4. API controller
5. Web: page view models (list, editor, preview)
6. Web controller
7. Module `boot()` — register routes
8. Leaf templates (list, editor)
9. Editor JS

---

## Type-specific field reference

### Book

| Purpose | Field | Type | Notes |
|---|---|---|---|
| Primary info | `title` | `String` | Required; maps to `Preview.primaryInfo` |
| Secondary info | `author` | `String` | Required; maps to `Preview.secondaryInfo`. Property key in DB: `artist` (legacy) |
| Cover image | `cover` | `Image?` | DB key: `cover_id`. Named `cover`, not `artwork` |
| Genre | `genre` | `String?` | Optional |
| Release date | `releaseDate` | `Date?` | Optional |
| Resource URLs | `resourceURLs` | `[String]` | GoodReads, others |

Validation: title + author both required.

### Movie

| Purpose | Field | Type | Notes |
|---|---|---|---|
| Primary info | `title` | `String` | Required; maps to `Preview.primaryInfo` |
| Secondary info | — | — | Computed from `releaseDate` + `director` — see below |
| Cover image | `cover` | `Image?` | DB key: `cover_id`. Named `cover`, not `artwork` |
| Director | `director` | `String?` | Optional |
| Genre | `genre` | `String?` | Optional |
| Release date | `releaseDate` | `Date?` | Optional. **Requires migration** — model currently declares this as non-optional `Date`, needs altering to nullable |
| Resource URLs | `resourceURLs` | `[String]` | IMDb, Rotten Tomatoes |

Validation: title required.

`Preview.secondaryInfo` is a concatenated string: `"releaseDate, director"` — e.g. `"2023, Christopher Nolan"`. Omit whichever parts are nil. If both are nil, set `secondaryInfo` to nil. Update `PreviewModelMiddleware` for Movie accordingly.

**Migration required:** `Movie.releaseDate` is currently `Date` (non-nullable in the DB). Before implementing the editor, add a migration to alter `movies.release_date` to allow nulls, and change the Swift property to `Date?`.

### Podcast

| Purpose | Field | Type | Notes |
|---|---|---|---|
| Primary info | `episodeTitle` | `String` | Required; maps to `Preview.primaryInfo` |
| Secondary info | `title` | `String` | Show/series title; maps to `Preview.secondaryInfo` |
| Cover image | `artwork` | `Image?` | DB key: `artwork_id`. Named `artwork`, same as songs |
| Season | `seasonNumber` | `Int?` | Optional |
| Episode | `episodeNumber` | `Int?` | Optional |
| Genre | `genre` | `String?` | Optional |
| Release date | `releaseDate` | `Date?` | Optional |
| Resource URLs | `resourceURLs` | `[String]` | Apple Podcasts |

Validation: episodeTitle + title (show name) both required.

The lookup command searches on `resource_urls` (same pattern as songs). Duplicate detection finds: same episode URL already in the user's catalogue.

---

## Layer-by-layer guide

### 1. Platform metadata struct + extractors

**Song reference:** `Platform/Metadata/SongMetadata.swift`, `Platform/Extractors/MetadataExtractor+AppleMusicSong.swift`, `Platform/Platforms/Platform+SongMetadata.swift`

Create one metadata struct per type:

```
Platform/Metadata/BookMetadata.swift
Platform/Metadata/MovieMetadata.swift
Platform/Metadata/PodcastMetadata.swift
```

Each struct is `Encodable, AsyncResponseEncodable, Sendable`. Include only what can realistically be extracted from the source platform. When a field cannot be extracted, keep it `String?` and return `nil`.

**Book fields:** `title`, `author`, `cover` (URL string), `releaseDate`, `externalID`  
**Movie fields:** `title`, `director`, `cover`, `releaseDate`, `externalID`  
**Podcast fields:** `episodeTitle`, `showTitle`, `artwork` (URL string), `releaseDate`, `episodeNumber`, `seasonNumber`, `externalID`

Extractors live in `Platform/Extractors/`. The pattern: make an HTTP request, parse the response (HTML/JSON), return the typed metadata struct. See `MetadataExtractor+AppleMusicSong.swift` and `HTMLMetadataParser.swift` for the pattern.

**One working extractor per type** — same scope as Apple Music for songs:
- **Books → GoodReads** (`MetadataExtractor+GoodReads.swift`). GoodReads pages expose OpenGraph meta tags — use `HTMLMetadataParser` to extract title, author, cover image, publish year.
- **Movies → IMDb** (`MetadataExtractor+IMDb.swift`). IMDb exposes OpenGraph/schema.org — extract title, director (from `schema:director`), year, poster.
- **Podcasts → Apple Podcasts** (`MetadataExtractor+ApplePodcasts.swift`). Apple Podcasts pages expose OpenGraph — extract episode title, show name, artwork, release date, episode/season if present.

`Platform+Book/Movie/Podcast.swift` currently return `Platform<Void>` (display-only). Upgrade them to `Platform<BookMetadata>` etc. and register the extractor. Checker implementations for each platform already exist (`PlatformChecker+GoodReads.swift` etc.).

### 2. Commands extension (lookup, search, metadata)

**Song reference:** `Commands+Songs.swift`, `Command+LookupSong.swift`, `Command+SongSearch.swift`, `FetchSongMetadata.swift`

Add three commands to each type's `CommandCollection`:

```swift
let lookup: CommandFactory<String, Book?>       // URL → Book? (checks resource_urls)
let metadata: CommandFactory<URL, BookMetadata> // URL → BookMetadata
let search: CommandFactory<String?, BookSearchResult>
```

**Lookup** — identical pattern to `lookupSong`. Use `filter(.sql(unsafeRaw: "'\(escaped)' = ANY(\(schema).resource_urls)"))` substituting the correct table name.

**Search** — identical to `Command+SongSearch.swift`. The search result type (`BookSearchResult` etc.) mirrors `SongSearchResult`. Search joins the previews table and queries both the item title and associated notes bodies.

**Metadata** — identical pattern to `FetchSongMetadata.swift`. Uses `request.commands.catalogue.metadata` as the underlying fetcher and the type-specific `Platform<XMetadata>.x` composite platform.

The permissions `lookup` scope already exists in each type's `Permissions+X.swift` (follow Songs for the exact scope — filters to owner's items only).

### 3. Editor payload

**Song reference:** `SongEditorPayload.swift`

```
Books/Routes/Web/BookEditorPayload.swift
Movies/Routes/Web/MovieEditorPayload.swift
Podcasts/Routes/Web/PodcastEditorPayload.swift
```

Each is `Decodable, Sendable`. Contains:
- `_csrf: String?`
- `access: Access`
- All model fields (matching the HTML form field names via `CodingKeys`)
- `notes: [NoteEntry]` (same `NoteEntry` nested struct as `SongEditorPayload`)
- `artworkIdRaw: String?` + `artworkSourceURLRaw: String?` (cover/artwork image handling — use whichever term matches the type: `coverIdRaw`/`coverSourceURLRaw` for Book and Movie, `artworkIdRaw`/`artworkSourceURLRaw` for Podcast)
- Computed `coverId`/`artworkId`, `coverSourceURL`/`artworkSourceURL`, `filteredResourceURLs`

Add `init(payload: XEditorPayload, coverId: ImageID?)` (or `artworkId` for Podcast) on `XInput` (extension in this file, same as `SongEditorPayload.swift` bottom).

**Movie-specific:** `releaseDate` in the payload is `Date?`. The controller throws a clean validation error if it is nil when the model requires it (though the model is being made optional — so just pass through).

**Podcast-specific:** Include `seasonNumber: Int?` and `episodeNumber: Int?` as form fields.

### 4. API controller

**Song reference:** `SongsAPIController.swift`

```
Books/Routes/API/BooksAPIController.swift
Movies/Routes/API/MoviesAPIController.swift
Podcasts/Routes/API/PodcastsAPIController.swift
```

Route shape (identical to Songs, substituting the type name):

```
GET  /api/books/lookup?url=   → BookLookupResponse (private struct)
GET  /api/books/:bookID       → BookResponse
POST /api/books               → BookResponse
PUT  /api/books/:bookID       → BookResponse
DEL  /api/books/:bookID       → 204
POST /api/books/:bookID/notes → NoteResponse
```

The `LookupResponse` private struct exposes `id`, `title`, the "secondary" field (author/director/showTitle), and `detailURL`.

For the note-creation endpoint, load the song via `commands.X.fetch(id, for: .write)`, then use `commands.notes.create(CreateNoteInput(..., attachmentID: item.$preview.id))`, load `$attachment` and `$author` before returning.

### 5. Web: page view models

**Song reference:** `Page+Songs.swift`, `Page+Song.swift`, `Page+SongEditor.swift`, `Page+SongPreview.swift`

Each type needs these view model files (add to existing `Pages/` directory):

#### List view model (`Page+Xs.swift`)

The list page already uses the shared catalogue page (`/catalogue`). Type-specific list pages (`/books`, `/movies`, `/podcasts`) show only that type's items. Mirror `Page+Songs.swift`: use `commands.search(query)` which returns both items and matched notes, build preview cards.

`Template` name: `"Catalogue/Books/books"` etc.

#### Editor view model (`Page+BookEditor.swift` etc.)

Contains `XEditorViewModel: Encodable, Sendable` with:
- All form fields pre-populated for edit mode
- `NoteViewModel` nested struct (same as `SongEditorViewModel.NoteViewModel`)
- `artworkId`, `artworkSourceURL`, `artworkThumbnailURL`
- `submit: Form.Submit`
- `_csrf: String?`
- `error: String?`

Two `Page` statics: `createX` and `editX`. Both generate a CSRF token, store in session under `"csrf.editor"`.

**Movie-specific editor:** `releaseDate` is now optional on the model, same as Book. No special handling needed.

**Podcast-specific editor:** Add `seasonNumber: String` and `episodeNumber: String` (formatted as strings for the form; empty string when nil).

#### Preview view model (`Page+BookPreview.swift` etc.)

Mirrors `Page+SongPreview.swift`. Used by `POST /books/preview` — decodes the editor payload, renders a read-only preview card without saving. Lets the user see how the entry will appear before submitting.

### 6. Web controller

**Song reference:** `SongsWebController.swift`

```
Books/Routes/Web/BooksWebController.swift
Movies/Routes/Web/MoviesWebController.swift
Podcasts/Routes/Web/PodcastsWebController.swift
```

Route shape:

```
GET  /books              → page: .books  (list)
GET  /books/:bookID      → page: .book   (detail — already exists in Page+Book.swift)
GET  /books/new          → page: .createBook
POST /books/new          → createBook handler
GET  /books/metadata     → metadata handler (returns JSON — XMetadata)
GET  /books/lookup       → lookupDialog handler (returns HTML fragment or 404)
GET  /books/:bookID/edit → page: .editBook
POST /books/:bookID      → updateBook handler
POST /books/preview      → page: .bookPreview
POST /books/:bookID/notes → createNote handler
```

The `handleEditorSubmission` private method centralises create/update logic. Pattern is identical to `SongsWebController.handleEditorSubmission`. Key parts:

1. Decode `XEditorPayload`
2. Validate CSRF
3. `resolveArtwork` — same logic as Songs (check `artworkId` → check `artworkSourceURL` via gallery lookup → upload from URL)
4. Transaction: create/edit item → batch-create or sync notes
5. Redirect to `"/books/\(book.id!)"` on success
6. `renderEditorWithError` on failure — re-render editor with submitted values + error string

`editorErrorHTML` — same cases as Songs; customise the `badRequest` message (e.g., "Title and author are required.")

`lookupDialog` — renders `Template.alertDialog` with a link to the existing item. The dialog message uses the type-specific fields ("You already have \(book.title) by \(book.author).").

`createNote` — identical to Songs. Uses `XID` from path, fetches via `commands.X.fetch(id, for: .write)`, delegates to `commands.notes.create`.

**Movie-specific:** `releaseDate` is optional — no special validation needed beyond the standard validation in `MovieInput`.

### 7. Module `boot()` — register routes

**Song reference:** `Songs.swift`

Each module's `boot(routes:)` is currently empty. Register both controllers:

```swift
func boot(routes: RoutesBuilder) throws {
    let protectedRoutes = routes.grouped(SessionAuthenticator())
    try protectedRoutes.register(collection: BooksWebController())
    try protectedRoutes.register(collection: BooksAPIController())
}
```

Match whatever session/auth middleware Songs uses.

### 8. Leaf templates

**Song reference:** `Resources/Views/Catalogue/Songs/songs.leaf`, `song-editor.leaf`

#### List template (`books.leaf` / `movies.leaf` / `podcasts.leaf`)

Extends `Shared/page`. Body mirrors `songs.leaf`: search input, preview grid using shared preview card fragments. The only difference is the page title and the create-new link (`/books/new`).

#### Editor template (`book-editor.leaf` / `movie-editor.leaf` / `podcast-editor.leaf`)

Extends `Shared/page`. Closely mirrors `song-editor.leaf`. Include:
- CSRF hidden field
- `access` toggle (public/private)
- All type-specific text fields (label + input)
- Artwork picker (reuse `#include("Catalogue/artwork-picker")` or equivalent shared fragment — matches Songs exactly)
- `#include("Catalogue/resources-editor")` (reuse shared resource URL editor)
- Notes section (reuse `#include("Shared/note-textarea")` pattern from Songs editor)
- Submit button via `submit.action` and `submit.label`
- Error display block

**Type-specific form field differences:**

Book editor fields: title, author, genre, release date  
Movie editor fields: title, director, genre, release date  
Podcast editor fields: episode title, show title, season number, episode number, genre, release date

All three editors include the artwork picker and resource URLs editor — same as Songs.

Use `<input type="number" min="1">` for season/episode number fields in the podcast editor.

### 9. Editor JavaScript

**Song reference:** `Public/Scripts/Catalogue/Songs/song-editor.js`

```
Public/Scripts/Catalogue/Books/book-editor.js
Public/Scripts/Catalogue/Movies/movie-editor.js
Public/Scripts/Catalogue/Podcasts/podcast-editor.js
```

`resources-editor.js` is already shared — import it (via `<script>` tag in the editor template before the type-specific script).

Each editor JS file needs the same controllers as `song-editor.js`:

| Controller | Purpose | Reusable? |
|---|---|---|
| `MetadataController` | Fetches `GET /X/metadata?url=` on URL input | Type-specific endpoint |
| `AutofillController` | Fills form fields from metadata response | Type-specific field mapping |
| `LookupController` | Calls `GET /X/lookup?url=` to detect duplicates | Type-specific endpoint + message |
| `DuplicateAlertController` | Shows/hides the duplicate alert dialog | Copy directly — structure is identical |
| `EditorController` | Form validation, draft persistence (localStorage), date normalisation | Copy; adjust localStorage key and field list |
| `GalleryController` | Opens gallery panel for artwork selection | Copy directly |
| `DragAndDropController` | Drag-drop for artwork/URL | Copy directly |

`ResourceInputsController` is already in `resources-editor.js` — wire it in `DOMContentLoaded`, same as Songs.

**Autofill field mapping per type:**

Book: `title` ← `metadata.title`, `author` ← `metadata.author`, `releaseDate` ← `metadata.releaseDate`, `artworkSourceURL` ← `metadata.cover`  
Movie: `title` ← `metadata.title`, `director` ← `metadata.director`, `releaseDate` ← `metadata.releaseDate`, `artworkSourceURL` ← `metadata.cover`  
Podcast: `episodeTitle` ← `metadata.episodeTitle`, `title` (show) ← `metadata.showTitle`, `seasonNumber` ← `metadata.seasonNumber`, `episodeNumber` ← `metadata.episodeNumber`, `releaseDate` ← `metadata.releaseDate`, `artworkSourceURL` ← `metadata.artwork`

Use the same localStorage draft key convention as Songs: `"editor:book:{id}"` / `"editor:book:new"` (prefix is `editor:`, not `draft:`).

**Date normalization:** The release date input accepts free-form text. Use the shared `parseReleaseDate(str)` function from `Public/Scripts/Shared/date-parser.js` — load it in the editor template before the type-specific script. It handles `YYYY`, `dd-mm-yyyy` / `dd/mm/yyyy`, and ISO strings, returning a `Date` or `null`.

---

## Confirmed design decisions

1. **Movie release date** — optional (`Date?`). Requires a migration to alter `movies.release_date` to nullable before the editor ships.

2. **Movie secondary info** — concatenated `"releaseDate, director"` string (e.g. `"2023, Christopher Nolan"`). Either component is omitted when nil.

3. **Podcast lookup identity** — by resource URL, same as Songs. Revisit if URL instability becomes a problem in practice.

4. **Metadata extractors** — one working extractor per type: GoodReads (Books), IMDb (Movies), Apple Podcasts (Podcasts). Additional platforms can be added later without structural changes.

5. **Cover vs. artwork naming** — kept domain-appropriate: `cover` for Book and Movie (book cover, movie cover), `artwork` for Song and Podcast (album artwork, podcast artwork). The property names differ between types but map to the same underlying `image_id` slot in Preview.

---

## Common mistakes to avoid

- Never register routes from `configure()`. Routes go in `boot()`.
- `request.commandDB` everywhere — never `application.db`.
- `XEditorPayload` is only for web form POST submissions. `XPayload` (existing) is for API POST/PUT.  
- CSRF token: generate in the `Page` static, store in session, validate in `handleEditorSubmission` before any database work.
- Artwork resolution: always check gallery `lookup(url)` before `addFromURL` to avoid duplicate image uploads.
- `NoteInput` `access` must be AND-ed with the parent item's access (`entry.access && payload.access`) on create, to avoid a private item having a public note.
- For `sync` (edit path), pass `SyncNotesInput` with the parent's access — the sync command handles AND-ing access internally.
- `Movie.swift` line 65 has `self.id = id` in the memberwise init — `id` is not a parameter there. Remove this line when touching the Movie model for the `releaseDate` migration.
