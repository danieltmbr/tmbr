import Foundation

public struct CategoryResponse: Codable, Sendable {

    public let id: Int
    public let slug: String
    public let name: String
    public let kind: CatalogueCategoryKind
    public let route: String?
    public let icon: String?
    public let parentSlug: String?

    public init(
        id: Int,
        slug: String,
        name: String,
        kind: CatalogueCategoryKind,
        route: String?,
        icon: String?,
        parentSlug: String?
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.kind = kind
        self.route = route
        self.icon = icon
        self.parentSlug = parentSlug
    }
}
