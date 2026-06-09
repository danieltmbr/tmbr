import Foundation
import Core
import Fluent
import Vapor

extension Commands {
    var catalogueCategories: Commands.CatalogueCategories.Type { Commands.CatalogueCategories.self }
}

extension Commands {
    struct CatalogueCategories: CommandCollection, Sendable {

        let create: CommandFactory<String, CatalogueCategory>

        let find: CommandFactory<String, CatalogueCategory?>

        let list: CommandFactory<Void, [CatalogueCategory]>

        init(
            create: CommandFactory<String, CatalogueCategory> = .createCategory,
            find: CommandFactory<String, CatalogueCategory?> = .findCategory,
            list: CommandFactory<Void, [CatalogueCategory]> = .listCatalogueCategories
        ) {
            self.create = create
            self.find = find
            self.list = list
        }
    }
}

extension Command where Self == PlainCommand<String, CatalogueCategory> {

    static func createCategory(database: Database) -> Self {
        PlainCommand { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let slug = trimmed
                .lowercased()
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            guard !slug.isEmpty else {
                throw Abort(.badRequest, reason: "Category name is required")
            }
            let category = CatalogueCategory(slug: slug, name: trimmed, kind: .orphan)
            try await category.create(on: database)
            return category
        }
    }
}

extension CommandFactory<String, CatalogueCategory> {

    static var createCategory: Self {
        CommandFactory { request in
            .createCategory(database: request.commandDB)
                .logged(name: "Create category", logger: request.logger)
        }
    }
}

extension Command where Self == PlainCommand<String, CatalogueCategory?> {

    static func findCategory(database: Database) -> Self {
        PlainCommand { slug in
            try await CatalogueCategory.query(on: database)
                .filter(\.$slug == slug)
                .first()
        }
    }
}

extension CommandFactory<String, CatalogueCategory?> {

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
