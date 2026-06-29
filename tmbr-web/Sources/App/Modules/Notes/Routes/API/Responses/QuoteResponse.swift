import Foundation
import TmbrCore

extension QuoteResponse {

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
