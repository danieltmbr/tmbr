import Vapor

struct QuoteResponse: Content {
    
    let body: String
    
    let noteID: Int
    
    let preview: PreviewResponse
}
