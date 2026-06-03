import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

extension Command where Self == PlainCommand<Void, [String]> {

    static func listShallowCategories(database: Database) -> Self {
        PlainCommand { _ in
            try await Preview.query(on: database)
                .filter(\.$parentType == nil)
                .filter(\.$parentID == nil)
                .field(\.$category)
                .unique()
                .all()
                .compactMap(\.category)
        }
    }
}

extension CommandFactory<Void, [String]> {

    static var listShallowCategories: Self {
        CommandFactory { request in
            .listShallowCategories(database: request.commandDB)
            .logged(name: "List shallow categories", logger: request.logger)
        }
    }
}
