# Plan: Shallow Catalogue Items — Zero-Effort New Media Types

> Save this file to `tmbr-web/.claude/docs/plans/shallow-catalogue-items.md` at the start of implementation.

---

## Context

The Preview model is a polymorphic proxy used by every catalogue item. PR #153 made `parentID` nullable, which opened a new capability: a Preview with `parentType = "track"` and `parentID = nil` is an "orphan" — it has a title, secondary info, and external links, but no backing database model. Music tracks use this for the album tracklist, where an orphan is auto-promoted to a Song when the user taps it.

The same infrastructure generalises to **any media type a user wants to bookmark**: a YouTube video, a newsletter, an article, a film they can't find in the movie database yet. Instead of building a full Song/Book/Movie module, the user pastes a URL, gives it a title, and gets a full catalogue item with a detail page and notes — immediately, with zero new backend code.

The goal of this plan is to complete the last two pieces:
1. **Make notes work on shallow detail pages** (`/catalogue/item/:uuid`) — currently stubbed out
2. **Implement `/catalogue/new`** — the creation entry point that's wired into the compose panel but has no handler

---

## Feature Description

After this work, a user can:

1. Click the "URL from clipboard" button in the compose panel
2. Paste any URL + title (+ optional secondary info + access toggle)
3. Get redirected to a shallow detail page at `/catalogue/item/:uuid`
4. Read the page, click through to the URL, and add notes — exactly like any other catalogue item
5. See the item in their catalogue feed alongside songs, books, movies, etc.

Adding a new "type" later (e.g. "newsletter", "video") requires: adding a string constant, adding it to `CatalogueQueryMapper.catalogueTypes`, and optionally adding a dedicated compose action. No migration, no model, no commands.

---

## What Already Exists

- `GET /catalogue/item/:previewID` — `PreviewsWebController` + `Page+CatalogueItem` — renders a shallow detail page using `Catalogue/details.leaf`. Works, but notes are stubbed (`allowsNewNote = false`, `notes = []`, no POST route).
- `ComposeAction.clipboard` — compose panel button pointing to `/catalogue/new`. The button already exists in the UI; no handler exists yet.
- `HTMLMetadataParser` — already used by all catalogue type editors for OpenGraph / JSON-LD extraction. Reuse for autofill on the new form.
- `commands.notes.query(id:of:)` — existing note-loading pattern used by all type-specific detail pages.
- `commands.notes.create(input:)` — existing note-creation command; `CreateNoteInput.attachmentID` is a Preview UUID.
- Orphan Preview creation pattern — established in `importTracks` (Album/Playlist import). Direct `preview.save(on: db)` with `parentID: nil`.

---

## Implementation

### Step 1 — Wire notes onto `Page+CatalogueItem`

**File:** `Sources/App/Modules/Previews/Routes/Web/Pages/Page+CatalogueItem.swift`

Currently `notes = []` and `allowsNewNote = false` are hardcoded. Replace with:

```swift
extension Page {
    static var catalogueItem: Self {
        Page(template: .catalogueItem) { request in
            guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
                throw Abort(.badRequest)
            }
            async let preview = request.commands.previews.fetch(previewID, for: .read)
            let resolvedPreview = try await preview

            // Check ownership for note creation
            let currentUser = try? request.auth.require(User.self)
            let allowsNewNote = currentUser?.id == resolvedPreview.$parentOwner.id

            // Load notes attached to this Preview UUID directly
            let notes = try await request.commands.notes.list(attachmentID: previewID)

            return CatalogueItemViewModel(
                preview: resolvedPreview,
                notes: notes,
                allowsNewNote: allowsNewNote,
                baseURL: request.baseURL
            )
        }
    }
}
```

Update `CatalogueItemViewModel.init` to accept `notes` and `allowsNewNote` instead of hardcoding them.

**Note:** The note-loading call uses `attachmentID` (Preview UUID) directly — not `query(id:of:)` which requires a catalogue-item integer ID. Verify the exact command signature in `Commands+Notes.swift`; if no `list(attachmentID:)` variant exists, add one (it's a simple `Note.query(on:).filter(\.$attachment.$id == attachmentID).all()`).

---

### Step 2 — Add `POST /catalogue/item/:previewID/notes`

**File:** `Sources/App/Modules/Previews/Routes/Web/PreviewsWebController.swift`

Add the notes creation handler. This is simpler than the type-specific versions because we already have the Preview UUID — no "fetch item → get preview ID" indirection needed:

```swift
struct PreviewsWebController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped(SessionAuthenticator())
        routes
            .grouped(RecoverMiddleware())
            .get("catalogue", "item", ":previewID", page: .catalogueItem)
        protected
            .grouped(RecoverMiddleware())
            .post("catalogue", "item", ":previewID", "notes", use: createNote)
    }

    private func createNote(_ request: Request) async throws -> Response {
        guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
            return Response(status: .badRequest)
        }
        guard let payload = try? request.content.decode(NotePayload.self) else {
            return Response(status: .badRequest)
        }
        // Fetch preview to verify ownership (for: .write enforces this)
        let preview = try await request.commands.previews.fetch(previewID, for: .write)
        let input = CreateNoteInput(
            body: payload.body,
            access: payload.access,
            attachmentID: previewID
        )
        let note = try await request.commands.notes.create(input)
        let model = try NoteViewModel(note: note, isEditable: true)
        let view = try await Template.noteItem.render(NoteItemContext(note: model), with: request.view)
        return try await view.encodeResponse(for: request)
    }
}
```

**Verify** that `commands.previews.fetch(previewID, for: .write)` enforces ownership — look at the existing `FetchPreviewCommand` to confirm it throws `.forbidden` for non-owners, or add that check if absent.

---

### Step 3 — Add a `CreatePreviewItemCommand`

**New file:** `Sources/App/Modules/Previews/Commands/Command/Command+CreatePreviewItem.swift`

There is no command for creating a standalone orphan Preview. Add one:

```swift
struct CreatePreviewItemInput: Sendable {
    let title: String
    let subtitle: String?
    let access: Access
    let externalLink: String?   // the primary URL resource
    let parentType: String      // e.g. "link", "video" — caller provides
    let ownerID: UserID
}
```

The command creates a Preview directly (no `PreviewModelMiddleware` involved):
```swift
let preview = Preview(
    parentType: input.parentType,
    parentID: nil,
    parentAccess: input.access,
    parentOwner: input.ownerID
)
preview.primaryInfo = input.title
preview.secondaryInfo = input.subtitle
preview.externalLinks = [input.externalLink].compactMap { $0 }
try await preview.save(on: request.commandDB)
return preview
```

Add a computed property to `Commands+Previews.swift`:
```swift
extension Commands {
    // already exists — add createItem to the collection
    var createPreviewItem: CommandFactory<CreatePreviewItemInput, Preview> { ... }
}
```

---

### Step 4 — Implement `GET /catalogue/new` and `POST /catalogue/new`

**New file:** `Sources/App/Modules/Previews/Routes/Web/Pages/Page+CatalogueNew.swift`

The create-item page. ViewModel fields:
- `error: String?`
- `_csrf: String?`
- access toggle fields

**New route in `PreviewsWebController.boot`:**

```
GET  /catalogue/new  → page: .catalogueNew   (render the form)
POST /catalogue/new  → createItem handler
```

**`POST /catalogue/new` handler:**
1. Validate CSRF
2. Decode payload: `url: String?, title: String, subtitle: String?, access: Access`
3. `title` is required — re-render form with error if blank
4. Call `commands.previews.createPreviewItem(CreatePreviewItemInput(title:, subtitle:, access:, externalLink: url, parentType: "link", ownerID: user.id))`
5. Redirect to `/catalogue/item/\(preview.id!)`

**New template:** `Resources/Views/Catalogue/catalogue-new.leaf`

Simple form: URL field, title field, secondary info field, access toggle, submit. Extend `Shared/page`. The form requires auth — `PreviewsWebController` should guard this route group behind `SessionAuthenticator`.

---

### Step 5 — OpenGraph autofill on the new form

**New route:** `GET /catalogue/new/metadata?url=` (returns JSON)

Reuses `HTMLMetadataParser` (already used by all catalogue type editors). Returns:
```json
{ "title": "...", "subtitle": "...", "artworkURL": "https://..." }
```
Extracted from OpenGraph: `og:title` → title, `og:description` or `og:site_name` → subtitle, `og:image` → artworkURL.

**New JS file:** `Public/Scripts/Catalogue/catalogue-new.js`

Same pattern as other catalogue editor JS: on URL field `blur` / paste, call `/catalogue/new/metadata?url=...`, autofill title + subtitle if blank. Also show an artwork preview image (same pattern as other editors that preview artwork before save).

On submit, include `artworkSourceURL` in the payload. The handler resolves the artwork via the existing `resolveArtwork` gallery pattern — `lookup(url)` first to avoid duplicate uploads, then `addFromURL` if not found — and sets `preview.$image.id`.

This is a significant UX improvement and consistent with how all other catalogue editors handle artwork.

---

### Step 6 — User-defined category (parentType as a form field)

Instead of hardcoding `parentType = "link"`, let the user name their own categories — "cooking", "running", "inspiration", etc. This is the mechanism for zero-effort new types: no backend change required, the user just types a new category name.

**Form field:** A text input labelled "Category" with `<datalist>` autocomplete populated from the user's existing shallow-item categories.

**Getting existing categories:** The page context (`Page+CatalogueNew`) queries distinct `parentType` values from the user's shallow Previews (i.e. `parentID IS NULL`, `parentType NOT IN ('track')`). This list is passed to the ViewModel and rendered as `<datalist>` options on the form.

**On submit:** The `parentType` is taken from the form input — lowercased, stripped of leading/trailing whitespace. If blank, default to `"link"`.

**Validation:** Disallow `"track"` as a user-provided category (it's a reserved internal type). Otherwise accept any non-empty string.

---

### Step 7 — Catalogue feed visibility (dynamic, not static)

**File:** `Sources/App/Modules/Catalogue/Catalogue/Routes/CatalogueQueryMapper.swift`

Because users define their own category names, we cannot maintain a static `catalogueTypes` set. Instead, change the query logic to:

- **Known types** (`"song"`, `"album"`, `"playlist"`, `"book"`, `"movie"`, `"podcast"`) — always included, hardcoded set
- **Shallow items** — any Preview with `parentID IS NULL` and `parentType NOT IN ('track')` is always included

This means the mapper uses two query clauses OR'd together:
1. `parentType IN (known types) AND parentID IS NOT NULL`
2. `parentID IS NULL AND parentType != 'track'`

**Catalogue filter chips:** User-defined categories should appear as filter chips. When building the filter options, include distinct shallow `parentType` values from the user's Previews alongside the standard chips ("All", "Music", "Books", etc.). This requires a small query addition in the catalogue page context — fetch distinct shallow parentTypes for the current user and add them as filter options.

---

### Step 8 — Save this plan to the project

Copy this document to `tmbr-web/.claude/docs/plans/shallow-catalogue-items.md` as the durable project reference.

---

## Files to Create

| File | Purpose |
|------|---------|
| `Previews/Commands/Command/Command+CreatePreviewItem.swift` | New command for creating standalone orphan Previews |
| `Previews/Routes/Web/Pages/Page+CatalogueNew.swift` | View model + Page for the creation form (includes existing-categories query for datalist autocomplete) |
| `Resources/Views/Catalogue/catalogue-new.leaf` | Creation form template (URL, title, subtitle, category, access, artwork preview) |
| `Public/Scripts/Catalogue/catalogue-new.js` | OpenGraph autofill + artwork preview JS |

## Files to Modify

| File | Change |
|------|--------|
| `Previews/Routes/Web/Pages/Page+CatalogueItem.swift` | Load notes, set `allowsNewNote` from auth |
| `Previews/Routes/Web/PreviewsWebController.swift` | Add POST notes + GET/POST/metadata catalogue/new routes |
| `Previews/Commands/Commands+Previews.swift` | Add `createPreviewItem` and `listCategories` to command collection |
| `Catalogue/Catalogue/Routes/CatalogueQueryMapper.swift` | Replace static type set with two-clause query (known types + orphan Previews) |
| `Catalogue/Catalogue/Routes/Web/CatalogueWebController.swift` (or Page+Catalogue.swift) | Include user's shallow categories in filter chip options |

---

## Verification

1. **Notes on existing shallow page** — Navigate to an album detail page, click an unpromoted track link (goes to `/catalogue/item/:uuid`), confirm the notes section is visible and a new note can be created and persists on refresh.

2. **Compose flow** — Click the compose button → "URL from clipboard" → paste a URL (e.g. a YouTube link), fill in a title, submit → redirected to a new `/catalogue/item/:uuid` page with correct title and link.

3. **Autofill** — On the `/catalogue/new` form, paste a URL with OpenGraph tags and confirm title/subtitle autofill.

4. **Catalogue feed** — The newly created item appears in `/catalogue` and `/catalogue?type=link`.

5. **Regression** — Existing catalogue types (songs, books, albums) still create and display notes without change.
