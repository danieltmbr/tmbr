import Foundation
import WebCore
import WebAuth
import Vapor
import Fluent

extension Permission<Quote> {

    static var accessQuote: Permission<Quote> {
        Permission<Quote>(
            "Only quotes from public notes or published posts can be accessed by others."
        ) { user, quote in
            if let note = quote.note {
                if note.access == .public { return true }
                guard let user else { throw Abort(.unauthorized) }
                return note.$author.id == user.id || user.role == .admin
            }
            if let post = quote.post {
                if post.state == .published { return true }
                guard let user else { throw Abort(.unauthorized) }
                return post.$author.id == user.id || user.role == .admin
            }
            throw Abort(.internalServerError, reason: "Quote has neither note nor post source")
        }
    }
}

extension Permission<QueryBuilder<Quote>> {

    /// Restricts a quote query to rows the requesting user may see:
    /// - Note-sourced: note.access == 'public' OR note.author_id == user
    /// - Post-sourced: post.state == 'published' OR post.author_id == user
    ///
    /// Uses EXISTS subqueries to avoid the double-join issue that arose when the
    /// old permission joined Note directly on top of commands that also join Note.
    static var queryQuote: Permission<QueryBuilder<Quote>> {
        Permission<QueryBuilder<Quote>> { user, query in
            let noteCondition: String
            let postCondition: String

            if let userID = user?.id {
                noteCondition = "notes.access = 'public' OR notes.author_id = \(userID)"
                postCondition = "posts.state = 'published' OR posts.author_id = \(userID)"
            } else {
                noteCondition = "notes.access = 'public'"
                postCondition = "posts.state = 'published'"
            }

            query.filter(.sql(unsafeRaw: """
                (
                    quotes.note_id IS NOT NULL
                    AND EXISTS (
                        SELECT 1 FROM notes
                        WHERE notes.id = quotes.note_id
                        AND (\(noteCondition))
                    )
                )
                OR
                (
                    quotes.post_id IS NOT NULL
                    AND EXISTS (
                        SELECT 1 FROM posts
                        WHERE posts.id = quotes.post_id
                        AND (\(postCondition))
                    )
                )
                """))
        }
    }
}
