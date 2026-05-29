import Foundation

struct CatalogueQueryMapper: Sendable {

    // Virtual type chips that expand to multiple concrete category slugs.
    private static let virtualTypes: [String: Set<String>] = [
        "music": [Album.previewType, Playlist.previewType, Song.previewType],
    ]

    private let categories: [CatalogueCategory]

    init(categories: [CatalogueCategory] = []) {
        self.categories = categories
    }

    func toPreviewQuery(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        PreviewQueryInput(term: payload.term, categoryIDs: selectedCategoryIDs(from: payload.types))
    }

    func toNotesQuery(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        NoteQueryPayload(term: payload.term, categoryIDs: selectedCategoryIDs(from: payload.types), languages: payload.languages)
    }

    func toQuoteQuery(from payload: CatalogueQueryPayload) -> QuoteQueryPayload {
        QuoteQueryPayload(term: payload.term, categoryIDs: selectedCategoryIDs(from: payload.types))
    }

    private func selectedCategoryIDs(from slugs: Set<String>?) -> Set<UUID>? {
        guard let slugs else { return nil }
        let expanded = slugs.flatMap { Self.virtualTypes[$0] ?? [$0] }
        let matched = categories.filter { expanded.contains($0.slug) }.compactMap(\.id)
        return matched.isEmpty ? nil : Set(matched)
    }
}
