import Foundation
import Core
import Fluent
import Vapor

extension Commands {
    var catalogueCategories: Commands.CatalogueCategories.Type { Commands.CatalogueCategories.self }
}

extension Commands {
    struct CatalogueCategories: CommandCollection, Sendable {

        let find: CommandFactory<String, CatalogueCategory>

        let list: CommandFactory<Void, [CatalogueCategory]>

        init(
            find: CommandFactory<String, CatalogueCategory> = .findCategory,
            list: CommandFactory<Void, [CatalogueCategory]> = .listCatalogueCategories
        ) {
            self.find = find
            self.list = list
        }
    }
}

extension Command where Self == PlainCommand<String, CatalogueCategory> {

    static func findCategory(database: Database) -> Self {
        PlainCommand { slug in
            guard let category = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == slug)
                .first()
            else {
                throw Abort(.internalServerError, reason: "Catalogue category '\(slug)' not found")
            }
            return category
        }
    }
}

extension CommandFactory<String, CatalogueCategory> {

    static var findCategory: Self {
        CommandFactory { request in
            .findCategory(database: request.commandDB)
                .logged(name: "Find category", logger: request.logger)
        }
    }
}

extension Command where Self == PlainCommand<Void, [CatalogueCategory]> {

    static func listCatalogueCategories(database: Database) -> Self {
        PlainCommand { _ in
            try await CatalogueCategory.query(on: database)
                .filter(\.$kind != .promotable)
                .sort(\.$slug)
                .all()
        }
    }
}

extension CommandFactory<Void, [CatalogueCategory]> {

    static var listCatalogueCategories: Self {
        CommandFactory { request in
            .listCatalogueCategories(database: request.commandDB)
                .logged(name: "List catalogue categories", logger: request.logger)
        }
    }
}
