import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct CatalogueNewViewModel: Encodable, Sendable {

    private let url: String?
    private let title: String
    private let subtitle: String?
    private let category: String
    private let access: String
    private let categories: [String]
    private let error: String?

    init(
        url: String? = nil,
        title: String = "",
        subtitle: String? = nil,
        category: String = "",
        access: Access = .private,
        categories: [String] = [],
        error: String? = nil
    ) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.access = access.rawValue
        self.categories = categories
        self.error = error
    }
}

extension Template where Model == CatalogueNewViewModel {
    static let catalogueNew = Template(name: "Catalogue/catalogue-new")
}

extension Page {
    static var catalogueNew: Self {
        Page(template: .catalogueNew) { request in
            let user = try request.auth.require(User.self)
            let userID = try user.requireID()
            let categories = (try? await request.commands.previews.listShallowCategories(userID)) ?? []
            return CatalogueNewViewModel(categories: categories)
        }
    }
}
