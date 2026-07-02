import Vapor
import TmbrCore

extension CategoryResponse {

    init(category: CatalogueCategory) throws {
        self.init(
            id: try category.requireID(),
            slug: category.slug,
            name: category.name,
            kind: category.kind,
            route: category.route,
            icon: category.icon,
            parentSlug: category.parentSlug
        )
    }
}
