import Foundation

struct CatalogueQueryMapper: Sendable {
    
    private static let catalogueTypes: Set<String> = [
        Book.previewType,
        Movie.previewType,
        Podcast.previewType,
        Song.previewType,
    ]
    
    private let allowedTypes: Set<String>
    
    init(allowedTypes: Set<String> = Self.catalogueTypes) {
        self.allowedTypes = allowedTypes
    }
    
    func toPreviewQuery(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        PreviewQueryInput(types: filter(types: payload.types))
    }
    
    func toNotesQuery(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        NoteQueryPayload(term: payload.term, types: filter(types: payload.types))
    }
    
    func toQuoteQuery(from payload: CatalogueQueryPayload) -> QuoteQueryPayload {
        QuoteQueryPayload(term: payload.term, types: filter(types: payload.types))
    }
    
    private func filter(types: Set<String>?) -> Set<String> {
        guard let types else { return allowedTypes }
        return allowedTypes.filter { types.contains($0) }
    }
}
