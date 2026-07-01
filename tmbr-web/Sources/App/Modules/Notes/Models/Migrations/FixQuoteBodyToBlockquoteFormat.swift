import Fluent
import Markdown
import WebCore

/// Re-extracts all quote bodies using the updated `QuoteExtractor`, which now stores
/// bodies as full blockquote markdown (with `> ` prefix on every line).
///
/// **Why**: the extractor previously stored only the extracted text content. This caused
/// `CitationMarkdownFormatter` to mishandle cite spans (the source-range lookup for
/// InlineAttributes breaks when preceded by a hard-break marker). Storing the body as
/// valid blockquote markdown lets the formatter process citations in their natural
/// context, matching how they appear in the original note/post source.
///
/// Uses `QuoteReconciler` to update only rows whose body changed, so existing
/// `/quotes/<id>` permalinks remain valid.
struct FixQuoteBodyToBlockquoteFormat: AsyncMigration {

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

    func revert(on database: Database) async throws {
        // Data-only repair — no schema changes to roll back.
    }

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
