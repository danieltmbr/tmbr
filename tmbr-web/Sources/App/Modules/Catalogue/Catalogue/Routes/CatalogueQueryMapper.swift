import Foundation

struct CatalogueQueryMapper: Sendable {

    // Known model-backed types. Shallow user-defined categories are merged in per-request via init(shallowTypes:).
    static let catalogueTypes: Set<String> = [
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

    init(shallowTypes: [String]) {
        self.init(allowedTypes: Self.catalogueTypes.union(shallowTypes))
    }

    func toPreviewQuery(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        let (knownTypes, categories) = split(filter(types: payload.types))
        return PreviewQueryInput(term: payload.term, types: knownTypes, categories: categories)
    }

    func toNotesQuery(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        let (knownTypes, categories) = split(filter(types: payload.types))
        return NoteQueryPayload(term: payload.term, types: knownTypes, categories: categories)
    }

    func toQuoteQuery(from payload: CatalogueQueryPayload) -> QuoteQueryPayload {
        let (knownTypes, categories) = split(filter(types: payload.types))
        return QuoteQueryPayload(term: payload.term, types: knownTypes, categories: categories)
    }

    private func filter(types: Set<String>?) -> Set<String> {
        guard let types else { return allowedTypes }
        let expanded = types.flatMap { Self.virtualTypes[$0] ?? [$0] }
        return allowedTypes.filter { expanded.contains($0) }
    }

    private func split(_ types: Set<String>) -> (knownTypes: Set<String>?, categories: Set<String>?) {
        let known = types.intersection(Self.catalogueTypes)
        let cats = types.subtracting(Self.catalogueTypes)
        return (known.isEmpty ? nil : known, cats.isEmpty ? nil : cats)
    }
}
