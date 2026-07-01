import Fluent
import Markdown
import WebCore

/// Re-extracts all quote bodies after `QuoteExtractor` was updated to pre-convert
/// `cite:` inline attribute spans to `class: citation`.
///
/// **Why**: `CitationMarkdownFormatter`'s source-range lookup for cite spans breaks
/// when the stored body has `> ` blockquote prefixes — it locates `>` at column 1
/// instead of `^[`, causing `extractContent` to return an empty string and the span
/// to never be rewritten to `.citation`. Pre-converting in the extractor bypasses
/// that lookup entirely: `HTMLFormatter` (the no-spans fallback path) renders
/// `class: citation` spans correctly on its own.
struct FixQuoteCitationClass: AsyncMigration {

    func prepare(on database: Database) async throws {
        let notes = try await Note.query(on: database).all()
        for note in notes {
            guard let noteID = note.id else { continue }
            let existing = try await Quote.query(on: database)
                .filter(\.$note.$id == noteID)
                .all()
            try await reconcile(existing: existing, freshBodies: Document(parsing: note.body).quotes, on: database) { body in
                Quote(noteID: noteID, body: body)
            }
        }

        let posts = try await Post.query(on: database).all()
        for post in posts {
            guard let postID = post.id else { continue }
            let existing = try await Quote.query(on: database)
                .filter(\.$post.$id == postID)
                .all()
            try await reconcile(existing: existing, freshBodies: Document(parsing: post.content).quotes, on: database) { body in
                Quote(postID: postID, body: body)
            }
        }
    }

    func revert(on database: Database) async throws {}

    private func reconcile(
        existing: [Quote],
        freshBodies: [String],
        on database: Database,
        makeQuote: (String) -> Quote
    ) async throws {
        let actions = QuoteReconciler.plan(
            existing: existing.compactMap { q in q.id.map { .init(id: $0, body: q.body) } },
            freshBodies: freshBodies
        )
        for (id, newBody) in actions.toUpdate {
            guard let quote = existing.first(where: { $0.id == id }) else { continue }
            quote.body = newBody
            try await quote.update(on: database)
        }
        for body in actions.toInsert {
            try await makeQuote(body).create(on: database)
        }
        for id in actions.toDelete {
            guard let quote = existing.first(where: { $0.id == id }) else { continue }
            try await quote.delete(on: database)
        }
    }
}
