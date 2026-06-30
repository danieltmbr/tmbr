import Foundation
import TmbrCore
import WebAuth

extension NoteResponse {

    init(note: Note, baseURL: String) {
        let attachment = note.attachment
        let preview = PreviewResponse(preview: attachment, baseURL: baseURL)
        self.init(
            id: note.id!,
            access: note.access,
            attachment: preview,
            author: UserResponse(user: note.author),
            body: note.body,
            created: note.createdAt,
            language: note.language,
            quotes: note.quotes.compactMap { quote in
                guard let quoteID = quote.id else { return nil }
                return QuoteResponse(
                    id: quoteID,
                    body: quote.body,
                    createdAt: quote.createdAt ?? .now,
                    source: QuoteSource(
                        kind: .note,
                        title: attachment.primaryInfo,
                        subtitle: attachment.secondaryInfo,
                        type: attachment.catalogueCategory?.slug,
                        preview: preview,
                        noteID: note.id!,
                        postID: nil
                    )
                )
            }
        )
    }
}
