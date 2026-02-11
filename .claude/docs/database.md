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

Preview (previews)
  ├── parentID: Int           (polymorphic, not a FK — points to the item's table)
  ├── parentType: String      ("book", "song", "movie", "podcast")
  ├── parentOwner: User       (@Parent, key: "parent_owner")
  ├── parentAccess: Access    (enum)
  ├── primaryInfo: String     (title)
  ├── secondaryInfo: String?  (artist/author)
  ├── image: Image?           (@OptionalParent, key: "image_id")
  └── externalLinks: [String]
  UNIQUE(parent_type, parent_id)
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

Aggregated lists query only the `previews` table — no joins across entity-specific tables. Detail pages use `parentType` + `parentID` to fetch the actual item from its dedicated table.

Notes and Posts never reference parent entities directly — they hold a Preview FK (`attachment_id`), which provides the parent's type, ID, and owner. This avoids circular dependencies between modules and means Notes/Posts work with any Previewable entity without modification.

### Legacy Naming

**`attachment` is a legacy name.** On both Post and Note, the Preview FK property is named `attachment` (from when it was just an optional add-on to Posts). It should be understood as "parent catalogue item reference" and is a candidate for renaming.

### Previewable Protocol

Catalogue items conform to `Previewable`. The `PreviewModelMiddleware` automatically creates, updates, and deletes the associated Preview record in sync with the item's lifecycle — no manual Preview management needed. Each item type configures how its fields map to Preview's `primaryInfo`/`secondaryInfo`/`image`.

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
