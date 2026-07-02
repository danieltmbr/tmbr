import Foundation
import Vapor
import TmbrCore

extension QuoteResponse {

    init(quote: Quote, baseURL: String) throws {
        guard let id = quote.id else {
            throw Abort(.internalServerError, reason: "Quote missing id")
        }
        self.init(
            id: id,
            body: quote.body,
            createdAt: quote.createdAt ?? .now,
            source: try QuoteSource(quote: quote, baseURL: baseURL)
        )
    }

    /// Convenience for building a post-sourced response when the `Post` is already in scope,
    /// avoiding a redundant eager-load of `quote.$post`.
    init(quote: Quote, post: Post, baseURL: String) throws {
        guard let id = quote.id else {
            throw Abort(.internalServerError, reason: "Quote missing id")
        }
        self.init(
            id: id,
            body: quote.body,
            createdAt: quote.createdAt ?? .now,
            source: QuoteSource(post: post, postID: try post.requireID(), baseURL: baseURL)
        )
    }
}

extension QuoteSource {

    init(quote: Quote, baseURL: String) throws {
        if let note = quote.note, let noteID = quote.$note.id {
            self.init(note: note, noteID: noteID, baseURL: baseURL)
        } else if let post = quote.post, let postID = quote.$post.id {
            self.init(post: post, postID: postID, baseURL: baseURL)
        } else {
            throw Abort(.internalServerError, reason: "Quote has neither note nor post source")
        }
    }

    init(note: Note, noteID: NoteID, baseURL: String) {
        let attachment = note.attachment
        self.init(
            kind: .note,
            title: attachment.primaryInfo,
            subtitle: attachment.secondaryInfo,
            type: attachment.catalogueCategory?.slug,
            preview: PreviewResponse(preview: attachment, baseURL: baseURL),
            noteID: noteID,
            postID: nil
        )
    }

    init(post: Post, postID: PostID, baseURL: String) {
        self.init(
            kind: .post,
            title: post.title,
            subtitle: nil,
            type: nil,
            preview: post.attachment.map { PreviewResponse(preview: $0, baseURL: baseURL) },
            noteID: nil,
            postID: postID
        )
    }
}
