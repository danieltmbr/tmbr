import Foundation
import AuthKit

struct NoteResponse: Encodable, Sendable {
    
    private let id: NoteID
    
    private let access: Access
    
    private let attachment: PreviewResponse
    
    private let author: UserResponse
    
    private let body: String
    
    private let created: Date
    
    private let quotes: [QuoteResponse]
    
    init(
        id: NoteID,
        access: Access,
        attachment: PreviewResponse,
        author: UserResponse,
        body: String,
        created: Date,
        quotes: [QuoteResponse]
    ) {
        self.id = id
        self.access = access
        self.attachment = attachment
        self.author = author
        self.body = body
        self.created = created
        self.quotes = quotes
    }
    
    init(note: Note, baseURL: String) {
        self.init(
            id: note.id!,
            access: note.access,
            attachment: PreviewResponse(preview: note.attachment, baseURL: baseURL),
            author: UserResponse(user: note.author),
            body: note.body,
            created: note.createdAt ?? .now,
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
