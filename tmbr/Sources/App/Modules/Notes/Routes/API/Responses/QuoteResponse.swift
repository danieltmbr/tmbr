import Vapor

struct QuoteResponse: Content {
    
    private let body: String
    
    private let noteID: UUID
    
    private let preview: PreviewResponse
    
    init(
        body: String,
        noteID: UUID,
        preview: PreviewResponse
    ) {
        self.body = body
        self.noteID = noteID
        self.preview = preview
    }
    
    init(quote: Quote, baseURL: String) {
        self.init(
            body: quote.body,
            noteID: quote.$note.id,
            preview: PreviewResponse(
                preview: quote.note.attachment,
                baseURL: baseURL
            )
        )
    }
}
