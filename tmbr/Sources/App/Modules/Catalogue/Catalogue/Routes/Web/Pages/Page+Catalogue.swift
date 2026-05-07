import Vapor
import Core
import Foundation

struct PreviewViewModel: Encodable, Sendable {

    let date: String

    let href: String

    let index: Int

    let primaryInfo: String

    let secondaryInfo: String?

    let thumbnailURL: String?

    init(index: Int, preview: Preview, baseURL: String) {
        date = (preview.createdAt ?? .now).formatted(.publishDate)
        href = "/\(preview.parentType)s/\(preview.parentID)"
        self.index = index
        primaryInfo = preview.primaryInfo
        secondaryInfo = preview.secondaryInfo
        thumbnailURL = preview.image.map { "\(baseURL)/gallery/data/\($0.thumbnailKey)" }
    }
}

struct CatalogueFilterViewModel: Encodable, Sendable {

    let active: Bool

    let checkedInFilter: Bool

    let href: String

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
            let queryItems = req.url.query.flatMap {
                URLComponents(string: "/?" + $0)?.queryItems
            } ?? []
            let term = queryItems.first(where: { $0.name == "term" })?.value
            let selectedTypes: Set<String>? = {
                let values = queryItems.filter { $0.name == "types" }.compactMap(\.value)
                return values.isEmpty ? nil : Set(values)
            }()
            let mapper = CatalogueQueryMapper()
            let input = mapper.toPreviewQuery(from: CatalogueQueryPayload(term: term, types: selectedTypes))
            let previews = try await req.commands.previews.list(input)
            let baseURL = req.baseURL
            let isAllActive = selectedTypes == nil
            let typeFilterData: [(type: String, label: String)] = [
                (Song.previewType, "Songs"),
                (Book.previewType, "Books"),
                (Movie.previewType, "Movies"),
                (Podcast.previewType, "Podcasts"),
            ]
            return CatalogueViewModel(
                allActive: isAllActive,
                filters: typeFilterData.map { filter in
                    CatalogueFilterViewModel(
                        active: selectedTypes?.count == 1 && (selectedTypes?.contains(filter.type) ?? false),
                        checkedInFilter: selectedTypes?.contains(filter.type) ?? true,
                        href: "/catalogue?types=\(filter.type)",
                        label: filter.label,
                        type: filter.type
                    )
                },
                previews: previews.enumerated().map { (i, preview) in
                    PreviewViewModel(index: i + 1, preview: preview, baseURL: baseURL)
                },
                term: term
            )
        }
    }
}
