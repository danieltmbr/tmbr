import Vapor
import Core

struct CatalogueFilterViewModel: Encodable, Sendable {

    let active: Bool

    let checkedInFilter: Bool

    let href: String

    let iconName: String

    let label: String

    let type: String
}

struct CatalogueViewModel: Encodable, Sendable {

    let allActive: Bool

    let filters: [CatalogueFilterViewModel]

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
            let isAllActive = selectedTypes == nil
            let typeFilterData: [(type: String, label: String, iconName: String)] = [
                (Song.previewType, "Songs", "song"),
                (Book.previewType, "Books", "book"),
                (Movie.previewType, "Movies", "movie"),
                (Podcast.previewType, "Podcasts", "podcast"),
            ]
            return CatalogueViewModel(
                allActive: isAllActive,
                filters: typeFilterData.map { filter in
                    CatalogueFilterViewModel(
                        active: selectedTypes?.count == 1 && (selectedTypes?.contains(filter.type) ?? false),
                        checkedInFilter: selectedTypes?.contains(filter.type) ?? true,
                        href: "/catalogue?types=\(filter.type)",
                        iconName: filter.iconName,
                        label: filter.label,
                        type: filter.type
                    )
                },
                previews: previews.enumerated().map { (i, preview) in
                    PreviewViewModel(preview: preview, baseURL: baseURL)
                },
                term: term
            )
        }
    }
}
