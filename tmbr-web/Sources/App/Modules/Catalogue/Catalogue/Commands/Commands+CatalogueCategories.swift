import Foundation
import Core
import Fluent
import Vapor

extension Commands {
    var catalogueCategories: Commands.CatalogueCategories.Type { Commands.CatalogueCategories.self }
}

extension Commands {
    struct CatalogueCategories: CommandCollection, Sendable {

        let list: CommandFactory<Void, [CatalogueCategory]>

        init(list: CommandFactory<Void, [CatalogueCategory]> = .listCatalogueCategories) {
            self.list = list
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
