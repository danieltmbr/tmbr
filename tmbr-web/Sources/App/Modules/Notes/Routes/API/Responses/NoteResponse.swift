import Foundation
import TmbrCore
import AuthKit

extension NoteResponse {

    init(note: Note, baseURL: String) {
        self.init(
            id: note.id!,
            access: note.access,
            attachment: PreviewResponse(preview: note.attachment, baseURL: baseURL),
            author: UserResponse(user: note.author),
            body: note.body,
            created: note.createdAt ?? .now,
            language: note.language,
            quotes: note.quotes.map { quote in
                QuoteResponse(
                    body: quote.body,
                    noteID: note.id!,
                    preview: PreviewResponse(preview: note.attachment, baseURL: baseURL)
                )
            }
        )
    }
}
