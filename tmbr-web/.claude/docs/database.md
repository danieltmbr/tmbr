# Database

PostgreSQL with Fluent ORM.

## Environment Variables

- Development: `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `DATABASE_NAME`
- Production: `DATABASE_URL` (connection string)

Migrations run automatically via `app.autoMigrate()` at startup.

## Schema Design

### Preview Pattern

**Preview** is a polymorphic proxy that enables any entity type to participate in aggregated lists, own Notes, and be referenced by Posts — without those children needing direct knowledge of the parent's concrete type.

Currently used by Catalogue items (Book, Song, Movie, Podcast), but the pattern is not Catalogue-specific. Any new entity type (e.g., a Friend/Contact) can adopt the same model: conform to `Previewable`, get a Preview, and immediately support Notes, Posts, and aggregated listing.

### Core Relationship Pattern

Children reference parents via Preview, not directly:

```
Previewable Entity (book/song/movie/podcast/any future type)
  ├── preview: Preview       (@Parent, required, key: "preview_id")
  ├── post: Post?            (@OptionalParent, key: "post_id")
  └── owner: User            (@Parent, key: "owner_id")

Image (images)
  ├── key: String             (storage path for the full-size file)
  ├── thumbnailKey: String?   (storage path for the resized thumbnail)
  ├── alt: String             (alt text)
  ├── size: Int               (bytes)
  ├── owner: User             (@Parent, key: "owner_id")
  └── sourceURL: String?      (original external URL — used for deduplication; see Gallery commands)

Preview (previews)
  ├── parentID: Int?          (nullable; nil = shallow placeholder; non-nil = backing catalogue model ID)
  ├── catalogueCategory: CatalogueCategory?   (@OptionalParent — identifies the item type and its kind)
  ├── parentOwner: User       (@Parent, key: "parent_owner")
  ├── parentAccess: Access    (enum)
  ├── primaryInfo: String     (title)
  ├── secondaryInfo: String?  (artist/author)
  ├── image: Image?           (@OptionalParent, key: "image_id")
  └── externalLinks: [String]
  ID type: UUID (not Int like other models)

Post (posts)
  ├── attachment: Preview?    (@OptionalParent, key: "attachment_id")
  ├── author: User            (@Parent, key: "author_id")
  ├── state: .published|.draft
  └── content, title, createdAt

Note (notes)
  ├── attachment: Preview     (@Parent, required, key: "attachment_id")
  ├── author: User            (@Parent, key: "author_id")
  ├── access: Access          (public/private per-note)
  ├── body: String
  └── quotes: [Quote]         (@Children)

Quote (quotes)
  └── note: Note              (@Parent, key: "note_id", cascade delete)
```

### Why This Structure

Aggregated lists query only the `previews` table — no joins across entity-specific tables. Detail pages use `catalogueCategory` + `parentID` to fetch the actual item from its dedicated table.

Notes and Posts never reference parent entities directly — they hold a Preview FK (`attachment_id`), which provides the parent's type, ID, and owner. This avoids circular dependencies between modules and means Notes/Posts work with any Previewable entity without modification.

### Promotable Items (Shallow Placeholders)

Some catalogue entries are **shallow placeholders** — they have a Preview record but no backing first-class model. The `CatalogueCategory.Kind` enum controls this:

| Kind | Description | `parentID` | Can have Notes? | Example |
|------|-------------|------------|-----------------|---------|
| `.entry` | Model-backed, appears in feed | non-nil | Yes | Song, Album, Book, Movie, Playlist, Podcast |
| `.promotable` | Shallow placeholder awaiting promotion | nil → non-nil after promotion | No → Yes after promotion | Track |
| `.orphan` | User-defined, no backing model | nil | Yes | Recipe, Guide, Link |
| `.virtual` | Display-only grouping | nil | Yes (no use case yet) | Music |

**Key rule: use `catalogueCategory?.kind.isShallow` (not `parentID == nil`) to test whether an item can have notes.** Orphan and virtual items also have `parentID == nil` but are not shallow and can accept Notes.

#### Promotable Lifecycle (Track → Song)

1. **Import**: A `Preview` is created with `parentID = nil` and `kind = .promotable`. No Song model exists yet.
2. **User accesses track**: The app prompts to promote. `POST /api/songs/promote` is called.
3. **Promotion**: A `Song` model is created with `adoptingPreviewID` set to the track's Preview UUID. `PreviewModelMiddleware` calls `preview.adopt(parentID: songID, categoryID: songCategoryID, ...)` — setting `parentID` to the Song's Int ID and changing the category to "song" (kind = `.entry`).
4. **After promotion**: The same Preview UUID now has a non-nil `parentID` and a `.entry` kind. Notes can now be attached.

The `ContainerEntry` for an album/playlist tracklist always points to the same Preview UUID regardless of whether it has been promoted.

#### Deletion Behaviour

When removing a container entry from a tracklist:
- **`kind == .promotable`** (still shallow): delete the Preview record (ContainerEntry cascades via FK)
- **`kind != .promotable`** (promoted to Song): delete only the ContainerEntry, preserve the Preview and its backing Song

This logic lives in `Command+DeleteContainerEntries.swift` and `Command+SyncContainerEntries.swift`.

### Legacy Naming

**`attachment` is a legacy name.** On both Post and Note, the Preview FK property is named `attachment` (from when it was just an optional add-on to Posts). It should be understood as "parent catalogue item reference" and is a candidate for renaming.

### Previewable Protocol

Catalogue items conform to `Previewable`. The `PreviewModelMiddleware` automatically creates, updates, and deletes the associated Preview record in sync with the item's lifecycle — no manual Preview management needed. Each item type configures how its fields map to Preview's `primaryInfo`/`secondaryInfo`/`image`.

### Adding a New Catalogue Item Type

1. Create directory under `Catalogue/` (e.g., `Catalogue/Games/`)
2. Conform model to `Previewable` protocol
3. Configure field mappings to Preview's `primaryInfo`/`secondaryInfo`/`image`
4. Register in `Catalogue.swift`'s inner `ModuleRegistry`

`PreviewModelMiddleware` automatically manages Preview records — no manual Preview creation needed.

### Quotes

**Quotes are ephemeral.** Quote entities are auto-extracted from a Note's markdown block quotes on every save. All existing Quotes for a Note are deleted and regenerated on each update. **Quote IDs are not stable** — never rely on persistent Quote IDs.

## Fluent Query Patterns

### JOIN vs Eager Loading

These serve different purposes and are **not interchangeable**:

- `.with(\.$relation)` — Eager loads related records AFTER the main query runs. Does NOT add a JOIN to the SQL.
- `.join(Model.self, on: ...)` — Adds an actual SQL JOIN, required when filtering on related model columns.

### Critical Rule

If you filter on a related model's columns using `.filter(RelatedModel.self, \.$column == value)`, you **MUST** add an explicit `.join()` first. Otherwise PostgreSQL throws "missing FROM-clause entry for table".

```swift
// WRONG - filters on Preview without joining it
let query = Note
    .query(on: database)
    .with(\.$attachment)  // This is eager loading, NOT a join
    .filter(Preview.self, \.$parentType == type)  // ERROR: missing FROM-clause

// CORRECT - join before filtering
let query = Note
    .query(on: database)
    .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
    .with(\.$attachment)  // Still needed for eager loading the relationship
    .filter(Preview.self, \.$parentType == type)  // Now works
```

The `.with()` is still needed if you want the relationship populated on the returned models — the JOIN only makes the table available for filtering/sorting.
