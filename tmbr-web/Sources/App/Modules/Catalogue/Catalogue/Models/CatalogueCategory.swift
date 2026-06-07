import Fluent
import Foundation

final class CatalogueCategory: Model, @unchecked Sendable {

    static let schema = "catalogue_categories"

    typealias IDValue = UUID

    @ID(key: .id)
    var id: UUID?

    @Field(key: "slug")
    var slug: String

    @Field(key: "name")
    var name: String

    @Enum(key: "kind")
    var kind: Kind

    @OptionalField(key: "route")
    var route: String?

    @OptionalField(key: "icon")
    var icon: String?

    enum Kind: String, Codable, CaseIterable {
        case catalogue   // model-backed items visible in the feed: song, album, book, movie, playlist, podcast
        case promotable  // shallow placeholder awaiting promotion: track
        case orphan      // user-defined, no backing model: recipe, guide, link, …
    }

    init() {}

    init(slug: String, name: String, kind: Kind, route: String? = nil, icon: String? = nil) {
        self.slug = slug
        self.name = name
        self.kind = kind
        self.route = route
        self.icon = icon
    }
}
