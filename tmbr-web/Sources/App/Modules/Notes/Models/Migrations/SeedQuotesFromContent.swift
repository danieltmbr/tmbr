import Fluent
import Markdown
import WebCore

struct SeedQuotesFromContent: AsyncMigration {

    func prepare(on database: Database) async throws {
        let notes = try await Note.query(on: database).all()
        for note in notes {
            guard let noteID = note.id else { continue }
            for body in Document(parsing: note.body).quotes {
                try await Quote(noteID: noteID, body: body).create(on: database)
            }
        }

        let posts = try await Post.query(on: database).all()
        for post in posts {
            guard let postID = post.id else { continue }
            for body in Document(parsing: post.content).quotes {
                try await Quote(postID: postID, body: body).create(on: database)
            }
        }
    }

    func revert(on database: Database) async throws {
        try await Quote.query(on: database).delete()
    }
}
