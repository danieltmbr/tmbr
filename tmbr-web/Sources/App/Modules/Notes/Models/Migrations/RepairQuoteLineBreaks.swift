import Fluent
import Markdown
import WebCore

/// Repairs `Quote.body` rows that were stored with incorrect line-break encoding.
///
/// **Root cause**: `QuoteExtractor` stored soft/line breaks as plain `\n`. When the body
/// was re-parsed for HTML rendering, those became `SoftBreak` nodes, which
/// `HTMLFormatter` emits as a literal `\n` — collapsed to a space by the browser.
/// Additionally, multi-paragraph blockquotes (blank `>` lines) had their paragraph
/// boundaries silently dropped, joining adjacent stanzas with no separator.
///
/// **Fix**: `QuoteExtractor` now stores hard breaks as `\\\n` (CommonMark hard-break
/// syntax) and inserts `\n\n` between paragraphs. This migration re-extracts every
/// note/post quote with the corrected extractor and reconciles against existing rows,
/// preserving quote UUIDs so `/quotes/<id>` permalinks remain valid.
struct RepairQuoteLineBreaks: AsyncMigration {

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

    // MARK: - Private

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
