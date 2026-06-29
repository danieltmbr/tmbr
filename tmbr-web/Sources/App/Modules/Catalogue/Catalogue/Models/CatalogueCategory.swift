import Fluent
import Foundation
import TmbrCore

final class CatalogueCategory: Model, @unchecked Sendable {

    static let schema = "catalogue_categories"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Field(key: "slug")
    var slug: String

    @Field(key: "name")
    var name: String

    @Enum(key: "kind")
    var kind: CatalogueCategoryKind

    @OptionalField(key: "route")
    var route: String?

    @OptionalField(key: "icon")
    var icon: String?

    @OptionalField(key: "parent_slug")
    var parentSlug: String?

    typealias Kind = CatalogueCategoryKind

    init() {}

    init(
        slug: String,
        name: String,
        kind: CatalogueCategoryKind,
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

