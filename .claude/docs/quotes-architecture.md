# Quotes Architecture

Quotes are blockquotes extracted from markdown sources (notes and blog posts).
They are first-class objects: each quote has a stable UUID so it can be
deep-linked, shared, and cached on the native app without links breaking when
the source is edited.

---

## Identity model

Each `Quote` row has a **user-generated UUID** assigned once on first extraction
and stored permanently. The UUID is *never* derived from the quote text — it is
assigned at insertion time and preserved across source edits by the reconcile
algorithm described below.

### Reconcile algorithm (content-match + residual pairing)

Run on every note or post save, after the new blockquote list is extracted:

1. **Exact-text match** — for each freshly-extracted body, find an existing row
   with identical text (greedy, first-match). That row keeps its UUID and
   `created_at`. Handles unchanged quotes and pure reordering.

2. **Residual pairing** — remaining (unmatched) old rows and remaining new bodies
   are paired in document order. Each pair keeps the old UUID and updates the body
   in place. This is what makes a typo-fix preserve the shared link.

3. **Surplus new** bodies (more new than old) get a fresh UUID and `created_at`.

4. **Surplus old** rows (more old than new) are deleted. A shared link to a
   deleted quote will 404, which is correct — the content is gone.

The pure planning function lives in `web-core/Sources/WebCore/Markdown/QuoteReconciler.swift`
and is independently tested. The Fluent-level application is in
`NoteModelMiddleware` and `PostModelMiddleware` in `tmbr-web`.

### Future consideration: fuzzy / edit-distance matching

The one edge case residual pairing handles poorly is a quote that is **edited
AND moved in the same save**: order-pairing may pair the wrong old row. A future
upgrade could replace the residual-pairing step with Levenshtein similarity
scoring (score every old × new pair, greedily pair above a threshold). Trade-offs:

- Requires threshold tuning (no universal right value).
- Two similar-but-distinct quotes can be silently mis-paired.
- More code, heuristic behaviour harder to test.

Adopt only if real-world "edit and move in one save" churn is observed breaking
links in practice. The residual-pairing step is an isolated function in
`QuoteReconciler.plan`, so this upgrade is additive and self-contained.

---

## Source model

A `Quote` row has exactly one source: a note **or** a post (enforced in code).
Both nullable FKs exist in the schema; only one is set per row.

```
quotes
  id          UUID   PK (user-generated, stable)
  note_id     UUID?  FK → notes.id  ON DELETE CASCADE
  post_id     INT?   FK → posts.id  ON DELETE CASCADE
  body        TEXT   NOT NULL
  created_at  TIMESTAMPTZ
```

Extraction is source-agnostic: `web-core/Sources/WebCore/Markdown/QuoteExtractor.swift`
takes a markdown string and returns `[String]`. `Post.content` is passed in
exactly the same way as `Note.body`.

### Attribution

| Source | `QuoteSource.title` | `subtitle` | `type` | `preview` | deep-link id |
|--------|---------------------|------------|--------|-----------|--------------|
| Note   | `note.attachment.primaryInfo` | `note.attachment.secondaryInfo` | category slug (song/book/…) | `PreviewResponse` of the attachment | `noteID` |
| Post   | `post.title` | `nil` | `nil` | post's optional `PreviewResponse` | `postID` |

Visibility:
- Note quote visible if `note.access == .public` (or the requesting user is the
  author/admin).
- Post quote visible if `post.state == .published` (or the requesting user is the
  author/admin).

---

## Wire contract (`tmbr-core`)

```swift
// IDs.swift
public typealias QuoteID = UUID

// QuoteResponse.swift
public struct QuoteResponse: Codable, Sendable {
    public let id: QuoteID
    public let body: String
    public let createdAt: Date
    public let source: QuoteSource
}

public struct QuoteSource: Codable, Sendable {
    public enum Kind: String, Codable, Sendable { case note, post }
    public let kind: Kind
    public let title: String
    public let subtitle: String?
    /// Category slug ("song", "book", …). nil for post-sourced quotes.
    public let type: String?
    /// Catalogue preview (note-sourced) or post's optional artwork (post-sourced).
    public let preview: PreviewResponse?
    /// Set when kind == .note
    public let noteID: NoteID?
    /// Set when kind == .post
    public let postID: PostID?
}
```

`QuoteResponse` was previously unused in the native app (`QuoteResponse` existed
but no endpoint consumed it in-app). This redesign is a breaking DTO change but
has no migration cost on the mobile side — `QuoteRecord` already anticipated a
stable identity and needs to be updated to key on `QuoteID`.

---

## Web (`tmbr-web`)

### Pages (follow-up, not in the backend-foundation build)

- **`GET /quotes`** — renders a single random quote (calls `Command+RandomQuote`,
  SQL `RANDOM()`). One-at-a-time layout: quote body large and centred,
  attribution below. Refreshing the page picks a new random quote.

- **`GET /quotes/list`** — plain list. Each row: a `<blockquote>` with the body
  as plain text, an attribution line (source title · type, linked to the source
  item/post). Supports `?term=` search (calls `Command+SearchQuote`) and
  `?types=` filter (calls `Command+ListQuotes` with `categoryIDs`; reuses
  `CatalogueQueryMapper.toQuoteQuery`, `Panels/filter.leaf`, `filter.js`).
  No cards, no title column, no date column.

- **Nav** — add `<a href="/quotes">Quotes</a>` to
  `Resources/Views/Shared/site-navigation.leaf`.

### Controller / routing pattern

Follow `Page+Catalogue.swift` / `CatalogueWebController.swift`. Add a
`QuotesWebController` registered in `Notes.boot` alongside the existing
`QuotesAPIController`.

---

## Mobile Reader (`tmbr-app`)

### Surface (follow-up, not in the backend-foundation build)

- New Quotes tab in `app-core/Sources/AppCore/Shared/ContentView.swift`
  (or fold into the Search tab — decide at build time).
- Consume `/api/quotes/random` + `/api/quotes/search` via the
  `BasicRequest` / `RequestLoader` pattern in
  `app-api/Sources/AppApi/Sync/SyncRequests.swift` + `SyncLoaders.swift`.
  Public/unauthenticated GETs, matching Reader's other list requests.
- Cache via `app-persistence/.../AppPersistence/QuoteRecord.swift` (already
  defined; update to key on the new `QuoteID`).
- Render bodies using `MarkdownView` — the `QuoteBlock` / `.blockQuote` path
  already exists in `app-core/Sources/AppCore/Shared/Markdown/MarkdownView.swift`.

### Quote body on mobile

`QuoteResponse.body` is **plain text** (blockquote content with markdown
decorators stripped by `QuoteExtractor`). On mobile, wrap it in a blockquote
markdown string (`"> \(body)"`) so `MarkdownView` renders it through the
existing `QuoteBlock` view with the styled vertical bar. Attribution (title,
type, artwork) comes from `QuoteSource`.
