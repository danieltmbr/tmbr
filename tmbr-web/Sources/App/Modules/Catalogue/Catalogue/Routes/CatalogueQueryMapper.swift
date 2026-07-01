import Foundation

struct CatalogueQueryMapper: Sendable {

    private let categories: [CatalogueCategory]

    init(categories: [CatalogueCategory] = []) {
        self.categories = categories
    }

    func toPreviewQuery(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        PreviewQueryInput(
            term: payload.term,
            categoryIDs: selectedCategoryIDs(from: payload.types)
        )
    }

    func toNotesQuery(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        NoteQueryPayload(
            term: payload.term,
            categoryIDs: selectedCategoryIDs(from: payload.types),
            languages: payload.languages
        )
    }

    func toQuoteQuery(from payload: CatalogueQueryPayload) -> QuoteQueryPayload {
        QuoteQueryPayload(
            term: payload.term,
            // Only filter by category when the user has selected specific types.
            // Passing nil means "no filter" and keeps post-sourced quotes visible.
            categoryIDs: payload.types == nil ? nil : selectedCategoryIDs(from: payload.types)
        )
    }

    private func selectedCategoryIDs(from slugs: Set<String>?) -> Set<Int>? {
        guard let slugs else {
            // nil = all selected: exclude virtual categories (they have no direct preview assignments)
            let leafIDs = Set(categories.filter { $0.kind != .virtual }.compactMap(\.id))
            return leafIDs.isEmpty ? nil : leafIDs
        }
        // Expand collection slugs to their child category slugs
        let expanded = slugs.flatMap { slug -> [String] in
            let children = categories.filter { $0.parentSlug == slug }.map(\.slug)
            return children.isEmpty ? [slug] : children
        }
        let matched = categories.filter { expanded.contains($0.slug) }.compactMap(\.id)
        return matched.isEmpty ? nil : Set(matched)
    }
}
