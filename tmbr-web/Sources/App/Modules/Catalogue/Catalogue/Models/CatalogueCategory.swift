import Fluent
import Foundation

final class CatalogueCategory: Model, @unchecked Sendable {

    static let schema = "catalogue_categories"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

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

    @OptionalField(key: "parent_slug")
    var parentSlug: String?

    enum Kind: String, Codable, CaseIterable {
        case entry       // model-backed items visible in the feed: song, album, book, movie, playlist, podcast
        case promotable  // shallow placeholder awaiting promotion: track
        case orphan      // user-defined, no backing model: recipe, guide, link, …
        case virtual     // display-only grouping of related catalogue types, e.g. music → song/album/playlist
    }

    init() {}

    init(
        slug: String,
        name: String,
        kind: Kind,
        route: String? = nil,
        icon: String? = nil,
        parentSlug: String? = nil
    ) {
        self.slug = slug
        self.name = name
        self.kind = kind
        self.route = route
        self.icon = icon
        self.parentSlug = parentSlug
    }
}

extension CatalogueCategory.Kind {
    /// True for shallow placeholder items (currently: track) that cannot own Notes
    /// and are expected to be promoted to a first-class catalogue item.
    /// Use this instead of checking `preview.parentID != nil` — orphan and virtual items
    /// also have a nil parentID but are not shallow and can have notes.
    var isShallow: Bool { self == .promotable }
}
