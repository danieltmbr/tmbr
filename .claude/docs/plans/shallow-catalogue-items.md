# Plan: Shallow Catalogue Items — Zero-Effort New Media Types

---

## Revised Implementation (v2 — `CatalogueCategory` table)

> The original plan below describes the first attempt. This section documents what was actually built and why the approach changed.

### Why the first attempt was scrapped

The v1 approach encoded the "type" of a Preview in two separate columns:

| Column | Owner | Purpose |
|--------|-------|---------|
| `parent_type VARCHAR NOT NULL` | System | Identifies the backing model (song, album, track, …) |
| `category VARCHAR` | User | User-defined orphan type (recipe, guide, link, …) |

This worked correctly but the split propagated complexity everywhere it was consumed:
- Every query command (`listPreviews`, `searchNote`, `listQuotes`, `randomQuote`, `searchQuote`) needed a `switch (types, categories)` clause that produced OR-grouped SQL.
- `NoteQueryPayload` and `QuoteQueryPayload` both carried `types: Set<String>?` AND `categories: Set<String>?`.
- `CatalogueQueryMapper` had a `split()` function that separated user-selected filter slugs into "known types" (filter by `parentType`) vs. "user categories" (filter by `category`).
- Filter chips required combining a compile-time-hardcoded set of known types with a runtime `SELECT DISTINCT category` query.

The root cause: two different columns encoding the same concept ("what kind of thing is this Preview?").

### The v2 design: `catalogue_categories` table

A single `catalogue_categories` table is the source of truth for every kind of Preview entity. All types — system model-backed, promotable track placeholders, and user-defined orphan types — live in one place.

```
catalogue_categories
├── id       UUID  PK
├── slug     VARCHAR  UNIQUE  -- normalized key (lowercase, trimmed, spaces collapsed)
├── name     VARCHAR          -- display value (original user casing, e.g. "Guided Run")
└── kind     VARCHAR          -- 'catalogue' | 'promotable' | 'orphan'
```

| `kind` | Examples | Appears in feed? | Appears as filter chip? |
|--------|----------|-----------------|------------------------|
| `catalogue` | song, album, book, movie, playlist, podcast | Yes (when `parentID != nil`) | Yes |
| `promotable` | track | No (until promoted to a song) | No |
| `orphan` | recipe, guide, link, … | Yes | Yes |

`Preview` now holds a single FK instead of two string columns:

```
previews
├── category_id  UUID  FK → catalogue_categories(id)   -- replaces parent_type + category
└── parent_id    INT?                                  -- still present; nil for orphans + track placeholders
```

### Slug vs. name

`slug` is the normalized deduplication key: lowercased, trimmed, internal runs of whitespace collapsed. `name` preserves the author's original casing for display ("Guided Run", not "guided run"). Upsert always matches on `slug`, so two users typing "Guided Run" and "guided run" resolve to the same row.

System categories are seeded with capitalised names (Song, Album, Book, Movie, Playlist, Podcast, Track) during the `CreateCatalogueCategories` migration.

### Query simplification

With a single FK, every type filter becomes one clause:

```swift
// Before (v1) — required switch on (types, categories) to produce OR-grouped SQL
switch (input.types, input.categories) {
case (let types?, let cats?):
    query.group(.or) { ... }
...
}

// After (v2) — one filter regardless of whether IDs are system types or orphan types
if let categoryIDs = input.categoryIDs {
    query.filter(\.$catalogueCategory.$id ~~ categoryIDs)
}
```

`NoteQueryPayload`, `QuoteQueryPayload`, and `PreviewQueryInput` all collapsed from two optional sets to one: `categoryIDs: Set<UUID>?`.

`CatalogueQueryMapper` lost `split()` entirely. It now resolves user-selected slug strings (from URL params) to UUIDs via `selectedCategoryIDs(from:)`, handling virtual type expansion ("music" → {album, playlist, song}) the same as before.

### Filter chips

```swift
// Before (v1)
let shallowCategories = try await req.commands.previews.listShallowCategories()  // SELECT DISTINCT
let mapper = CatalogueQueryMapper(shallowTypes: shallowCategories)
let chips = [FilterItemViewModel].catalogue + shallowCategories.map { ... }      // combined static + dynamic

// After (v2)
let allCategories = try await req.commands.catalogueCategories.list()  // WHERE kind != 'promotable'
let mapper = CatalogueQueryMapper(categories: allCategories)
let chips = allCategories.map { FilterItemViewModel(icon: ..., label: cat.name, value: cat.slug) }
```

One query. No static list to maintain. No joining of compile-time and runtime data.

### Orphan creation

When a user creates a shallow item with a new category name, `CreatePreviewItemCommand` upserts into `catalogue_categories`:

```swift
let slug = name.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")
if let existing = try await CatalogueCategory.query(on: db).filter(\.$slug == slug).first() {
    category = existing
} else {
    category = CatalogueCategory(slug: slug, name: name, kind: .orphan)
    try await category.create(on: db)
}
preview.$catalogueCategory.id = category.id!
```

The category row is created on first use, no separate admin step required.

### Adoption (model-backed types)

`PreviewModelMiddleware` now looks up the `CatalogueCategory` row by slug before setting the FK:

```swift
let category = try await CatalogueCategory.query(on: db).filter(\.$slug == M.previewType).first()!
preview.adopt(parentID: ..., categoryID: category.id!, ...)
```

One extra DB read per model creation — acceptable since it's not a hot path and these category rows are always in the PostgreSQL buffer cache.

### Migration path

The v1 migration `AddPreviewCategory.swift` was removed (it was only on the feature branch). It is replaced by two migrations registered in `Previews.swift`:

1. **`CreateCatalogueCategories`** — creates the table and seeds the 7 system rows.
2. **`MigratePreviewToCategoryID`** — adds `category_id` FK to `previews`, backfills from `parent_type`, drops `parent_type` and `category`.

**Dev note:** Anyone who ran `AddPreviewCategory` locally must revert first:
```bash
cd tmbr-web && swift run Backend revert
```

### Virtual types

The `"music"` virtual filter (which expands to album + playlist + song) remains hardcoded in `CatalogueQueryMapper`. Adding it to the DB would require a membership relationship (join table or array column) just to know what a virtual type expands to — significant schema weight for a UI shortcut that is 3 lines of code. Revisit if the set of virtual groups grows.

---

## Context (original v1 plan)

The Preview model is a polymorphic proxy used by every catalogue item. PR #153 made `parentID` nullable, which opened a new capability: a Preview with `parentType = "track"` and `parentID = nil` is an "orphan" — it has a title, secondary info, and external links, but no backing database model. Music tracks use this for the album tracklist, where an orphan is auto-promoted to a Song when the user taps it.

The same infrastructure generalises to **any media type a user wants to bookmark**: a YouTube video, a newsletter, an article, a film they can't find in the movie database yet. Instead of building a full Song/Book/Movie module, the user pastes a URL, gives it a title, and gets a full catalogue item with a detail page and notes — immediately, with zero new backend code.

---

## Feature Description

After this work, a user can:

1. Click the "URL from clipboard" button in the compose panel
2. Paste any URL + title (+ optional secondary info + access toggle)
3. Get redirected to a shallow detail page at `/catalogue/item/:uuid`
4. Read the page, click through to the URL, and add notes — exactly like any other catalogue item
5. See the item in their catalogue feed alongside songs, books, movies, etc.

Adding a new "type" later (e.g. "newsletter", "video") requires only: the user types a new category name in the form. No migration, no model, no commands.

---

## Architecture: `parentType` vs `category`

`parentType` is system-controlled and `category` is user-controlled — they are separate fields on `Preview`. This eliminates any collision between system-managed promotable placeholders (e.g. `"track"`) and user-defined labels:

| Record kind | `parentType` | `parentID` | `category` |
|---|---|---|---|
| Model-backed (Song, Book, etc.) | `"song"`, `"book"`, … | non-nil | nil |
| Track placeholder (system) | `"track"` | nil | nil |
| User-defined shallow item | **nil** | nil | `"link"`, `"recipes"`, … |

Shallow user-created items are identified by `parentType IS NULL AND parentID IS NULL`. No reserved-string guards are needed.

Track placeholders keep `parentType = "track"` for promotion identity. `PreviewModelMiddleware` looks up the preview by UUID during promotion and overwrites `parentType` with `"song"` via `adopt(parentID:parentType:...)`. The string "track" is never used as a lookup key during promotion, so a user naming their category "track" causes no conflict.

---

## What Already Exists (as of initial PR)

- `GET /catalogue/item/:previewID` — renders a shallow detail page, notes loaded, `allowsNewNote` from auth.
- `POST /catalogue/item/:previewID/notes` — creates a note on a shallow item.
- `GET /catalogue/new` / `POST /catalogue/new` — creation form with OpenGraph autofill, artwork, notes.
- `GET /catalogue/new/metadata?url=` — metadata fetch endpoint.
- `ComposeAction.clipboard` — compose panel button pointing to `/catalogue/new`.
- `HTMLMetadataParser` — used for OpenGraph autofill.
- `CreatePreviewItemCommand` — creates an orphan `Preview` with `category` set and `parentType` nil.
- `listShallowCategories` command — `SELECT DISTINCT category` for all public shallow items.
- `CatalogueQueryMapper` — splits types into `knownTypes` (filter on `parentType`) and `categories` (filter on `category`).
- `Request.createNoteResponse(attachmentID:)` — shared helper used by all 7 catalogue web controllers.
- API counterparts: `GET/POST /api/catalogue/item/:previewID`, `POST /api/catalogue/new`, `GET /api/catalogue/new/metadata`.

---

## Implementation

### Step 1 — Wire notes onto `Page+CatalogueItem` ✓

**File:** `Sources/App/Modules/Previews/Routes/Web/Pages/Page+CatalogueItem.swift`

Loads notes via `request.commands.notes.fetchByAttachment(previewID)`. Determines `allowsNewNote` via `request.permissions.previews.edit.grant(resolvedPreview)`.

---

### Step 2 — Add `POST /catalogue/item/:previewID/notes` ✓

Route and handler live in `CatalogueWebController`. Uses the shared `request.createNoteResponse(attachmentID:)` helper after verifying write permission with `commands.previews.fetch(previewID, for: .write)`.

---

### Step 3 — Add `CreatePreviewItemCommand` ✓

**File:** `Sources/App/Modules/Previews/Commands/Command/Command+CreatePreviewItem.swift`

Input struct:
```swift
struct CreatePreviewItemInput: Sendable {
    let title: String
    let subtitle: String?
    let access: Access
    let artworkID: ImageID?
    let externalLink: String?
    let category: String      // stored in preview.category, not parentType
    let ownerID: UserID
}
```

Creates a Preview with `category: input.category` and `parentType: nil` (no backing model).

---

### Step 4 — Implement `GET /catalogue/new` and `POST /catalogue/new` ✓

Routes and handlers in `CatalogueWebController`. `Page+CatalogueNew` renders the form. Handler validates title, resolves artwork via gallery lookup/upload, creates item via `CreatePreviewItemCommand`, creates notes in a transaction, redirects to `/catalogue/item/:uuid`.

**Template:** `Resources/Views/Catalogue/catalogue-new.leaf` — URL field, title field, subtitle, category autocomplete (`<datalist>`), access toggle, artwork picker, notes editor.

---

### Step 5 — OpenGraph autofill ✓

`GET /catalogue/new/metadata?url=` reuses `HTMLMetadataParser` via `request.commands.catalogue.metadata(url)`. Returns `CatalogueItemMetadataResponse` (title, subtitle, artworkURL from og:* tags).

`Public/Scripts/Catalogue/catalogue-new.js` autofills title/subtitle/artwork on URL field blur/change. Also shows an inline non-blocking hint if the user types a system type name (song, album, etc.) as a category.

---

### Step 6 — User-defined category ✓

The `category` field is a free-text input in the form. Defaults to `"link"` if blank. Lowercased and trimmed before storage. The `<datalist>` autocomplete is populated from `listShallowCategories()` (all existing public categories).

No reserved-string validation needed — `parentType` and `category` are separate columns, so no system type can collide with a user category.

---

### Step 7 — Catalogue feed visibility ✓

**File:** `Sources/App/Modules/Catalogue/Catalogue/Routes/CatalogueQueryMapper.swift`

`init(shallowTypes: [String])` merges user categories into `allowedTypes`. All `to*Query(from:)` methods call `split(_:)` to separate the filtered set into:
- `knownTypes` → filter on `parentType IN (...)` (model-backed items)
- `categories` → filter on `parentType IS NULL AND category IN (...)` (user shallow items)

Both are passed to `PreviewQueryInput`, `NoteQueryPayload`, `QuoteQueryPayload`. `Page+Catalogue` uses `Command.searchCatalogue(mapper:noteSearch:previewSearch:)` instead of inline search logic.

Filter chips: standard chips + one per shallow category from `listShallowCategories()`.

---

### Step 8 — Shared `createNote` extraction ✓

**File:** `Sources/App/Modules/Notes/Routes/Web/Request+CreateNoteResponse.swift`

Shared `Request` extension used by all 7 web controllers (Songs, Albums, Books, Movies, Podcasts, Playlists, Catalogue). Decodes `NotePayload`, creates note, renders `NoteItemContext`.

---

### Step 9 — API counterparts ✓

Added to `CatalogueAPIController`:

| Route | Response |
|---|---|
| `GET /api/catalogue/item/:previewID` | `PreviewResponse` |
| `POST /api/catalogue/item/:previewID/notes` | `NoteResponse` |
| `POST /api/catalogue/new` | `PreviewResponse` |
| `GET /api/catalogue/new/metadata?url=` | `CatalogueItemMetadataResponse` |

---

### Step 10 — `parentType`/`category` migration ✓

**File:** `Sources/App/Modules/Previews/Models/Migrations/AddPreviewCategory.swift`

- Makes `parent_type` nullable.
- Adds `category VARCHAR` column.
- Backfills: `UPDATE previews SET category = parent_type, parent_type = NULL WHERE parent_id IS NULL AND parent_type IS NOT NULL AND parent_type != 'track'`.

---

## Files Created

| File | Purpose |
|------|---------|
| `Previews/Commands/Command/Command+CreatePreviewItem.swift` | Creates standalone orphan Preview with `category` |
| `Previews/Commands/Command/Command+ListShallowCategories.swift` | `SELECT DISTINCT category` for all public shallow items |
| `Previews/Models/Migrations/AddPreviewCategory.swift` | Makes `parent_type` nullable, adds `category` column |
| `Previews/Routes/Web/Pages/Page+CatalogueNew.swift` | ViewModel + Page for creation form |
| `Resources/Views/Catalogue/catalogue-new.leaf` | Creation form template |
| `Public/Scripts/Catalogue/catalogue-new.js` | OpenGraph autofill + artwork + category hint JS |
| `Notes/Routes/Web/Request+CreateNoteResponse.swift` | Shared note creation helper for all web controllers |

## Files Modified

| File | Change |
|------|--------|
| `Previews/Models/Preview.swift` | `parentType: String?` (nullable), added `category: String?` |
| `Previews/Commands/Commands+Previews.swift` | Added `create`, `listShallowCategories` (Void input) |
| `Previews/Routes/Web/Pages/Page+CatalogueItem.swift` | Loads notes, sets `allowsNewNote` from auth |
| `Previews/Routes/Web/PreviewsWebController.swift` | Payload types only; no routes |
| `Previews/Routes/Web/PreviewViewModel.swift` | Handles nullable `parentType` |
| `Previews/Routes/API/Responses/PreviewResponse.swift` | Handles nullable `parentType`, passes `category` |
| `Catalogue/Catalogue/Routes/CatalogueQueryMapper.swift` | `init(shallowTypes:)` delegates, splits types/categories |
| `Catalogue/Catalogue/Routes/Web/CatalogueWebController.swift` | All catalogue routes + handlers |
| `Catalogue/Catalogue/Routes/Web/Pages/Page+Catalogue.swift` | Uses `searchCatalogue` command, category filter chips |
| `Catalogue/Catalogue/Routes/API/CatalogueAPIController.swift` | Added item/notes/new API endpoints |
| `Catalogue/Albums/Routes/Web/Pages/Page+Album.swift` | Handles nullable `parentType` in TrackViewModel |
| `Notes/Payloads/NoteQueryPayload.swift` | Added `categories: Set<String>?` |
| `Notes/Payloads/QuoteQueryPayload.swift` | Added `categories: Set<String>?` |
| `Notes/Commands/Note/Command+SearchNote.swift` | Two-clause OR filter for types + categories |
| `Notes/Commands/Quote/Command+ListQuotes.swift` | Two-clause OR filter |
| `Notes/Commands/Quote/Command+SearchQuote.swift` | Two-clause OR filter |
| `Notes/Commands/Quote/Command+RandomQuote.swift` | Two-clause OR filter |
| `Previews/Commands/Command/Command+ListPreviews.swift` | Added `categories` to `PreviewQueryInput`, two-clause filter |
| All 6 catalogue type web controllers | `createNote` delegates to `request.createNoteResponse(attachmentID:)` |
| `tmbr-core/Responses/PreviewResponse.swift` | Added `category: String?` (backward-compatible) |

---

## Verification

1. **Notes on shallow page** — Navigate to an album tracklist, tap an unpromoted track (`/catalogue/item/:uuid`), confirm notes section visible and a new note can be created and persists on refresh.
2. **Compose flow** — Click compose → "URL from clipboard" → paste URL + title → redirected to new `/catalogue/item/:uuid` with correct title and link.
3. **Autofill** — On `/catalogue/new`, paste a URL with OpenGraph tags and confirm title/subtitle/artwork autofill.
4. **Category hint** — Type "song" as a category name → inline non-blocking warning appears.
5. **Catalogue feed** — Newly created item appears in `/catalogue` and `/catalogue?type=link`.
6. **Track placeholder isolation** — Album tracks do NOT appear as filter chips or standalone catalogue items.
7. **User "track" category** — User can create `category = "track"` item; it appears in feed and does not interfere with album track promotion.
8. **Global shallow categories** — Log in as User A, create item with category "recipes". Log in as User B — "recipes" chip appears in `/catalogue`.
9. **API routes** — `POST /api/catalogue/new` creates item + returns `PreviewResponse`. `POST /api/catalogue/item/:uuid/notes` returns `NoteResponse`.
10. **Notes regression** — Songs, books, albums still create and display notes without change.
