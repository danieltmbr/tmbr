# Plan: Shallow Catalogue Items — Zero-Effort New Media Types

---

## Context

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
