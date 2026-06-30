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
}

extension QuoteSource {

    init(quote: Quote, baseURL: String) throws {
        if let note = quote.note, let noteID = quote.$note.id {
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
        } else if let post = quote.post, let postID = quote.$post.id {
            self.init(
                kind: .post,
                title: post.title,
                subtitle: nil,
                type: nil,
                preview: post.attachment.map { PreviewResponse(preview: $0, baseURL: baseURL) },
                noteID: nil,
                postID: postID
            )
        } else {
            throw Abort(.internalServerError, reason: "Quote has neither note nor post source")
        }
    }
}
