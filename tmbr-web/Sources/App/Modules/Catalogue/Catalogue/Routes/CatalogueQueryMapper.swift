import Foundation

struct CatalogueQueryMapper: Sendable {

    private static let catalogueTypes: Set<String> = [
        Album.previewType,
        Book.previewType,
        Movie.previewType,
        Playlist.previewType,
        Podcast.previewType,
        Song.previewType,
    ]

    // Virtual type chips that expand to multiple concrete previewTypes
    private static let virtualTypes: [String: Set<String>] = [
        "music": [Album.previewType, Playlist.previewType, Song.previewType],
    ]

    private let allowedTypes: Set<String>

    init(allowedTypes: Set<String> = Self.catalogueTypes) {
        self.allowedTypes = allowedTypes
    }

    func toPreviewQuery(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        PreviewQueryInput(term: payload.term, types: filter(types: payload.types))
    }

    func toNotesQuery(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        NoteQueryPayload(term: payload.term, types: filter(types: payload.types), languages: payload.languages)
    }

    func toQuoteQuery(from payload: CatalogueQueryPayload) -> QuoteQueryPayload {
        QuoteQueryPayload(term: payload.term, types: filter(types: payload.types))
    }

    private func filter(types: Set<String>?) -> Set<String> {
        guard let types else { return allowedTypes }
        let expanded = types.flatMap { Self.virtualTypes[$0] ?? [$0] }
        return allowedTypes.filter { expanded.contains($0) }
    }
}
