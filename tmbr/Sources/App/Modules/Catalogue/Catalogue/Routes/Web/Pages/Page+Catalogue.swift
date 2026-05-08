import Vapor
import Core

struct CatalogueViewModel: Encodable, Sendable {

    let filterItems: [FilterItemViewModel]

    let previews: [PreviewViewModel]

    let term: String?
}

extension Template where Model == CatalogueViewModel {
    static let catalogue = Template(name: "Catalogue/catalogue")
}

extension Page {
    static var catalogue: Self {
        Page(template: .catalogue) { req in
            let payload = try req.query.decode(CatalogueQueryPayload.self)
            let term = payload.term
            let selectedTypes = payload.types
            let result = try await req.commands.catalogue.search(payload)
            let baseURL = req.baseURL
            let typeFilterData: [(type: String, label: String, iconName: String)] = [
                (Song.previewType, "Songs", "song"),
                (Book.previewType, "Books", "book"),
                (Movie.previewType, "Movies", "movie"),
                (Podcast.previewType, "Podcasts", "podcast"),
            ]
            return CatalogueViewModel(
                filterItems: typeFilterData.map { filter in
                    FilterItemViewModel(
                        label: filter.label,
                        iconName: filter.iconName,
                        value: filter.type,
                        checked: selectedTypes?.contains(filter.type) ?? true
                    )
                },
                previews: result.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + result.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) },
                term: term
            )
        }
    }
}
