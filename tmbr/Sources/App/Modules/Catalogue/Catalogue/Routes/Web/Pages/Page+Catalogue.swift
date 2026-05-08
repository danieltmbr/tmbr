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
            let mapper = CatalogueQueryMapper()
            let input = mapper.toPreviewQuery(from: payload)
            let previews = try await req.commands.previews.list(input)
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
                previews: previews.map { preview in
                    PreviewViewModel(preview: preview, baseURL: baseURL)
                },
                term: term
            )
        }
    }
}
