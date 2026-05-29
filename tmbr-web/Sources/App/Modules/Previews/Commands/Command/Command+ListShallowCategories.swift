import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

/// Returns distinct parentType strings for the given user's shallow (parentID = nil, non-track) Previews.
extension Command where Self == PlainCommand<UserID, [String]> {

    static func listShallowCategories(database: Database) -> Self {
        PlainCommand { ownerID in
            let previews = try await Preview
                .query(on: database)
                .filter(\.$parentOwner.$id == ownerID)
                .filter(\.$parentID == nil)
                .filter(\.$parentType != "track")
                .field(\.$parentType)
                .all()
            let seen = NSMutableOrderedSet()
            for preview in previews {
                seen.add(preview.parentType)
            }
            return seen.array as? [String] ?? previews.map(\.parentType)
        }
    }
}

extension CommandFactory<UserID, [String]> {

    static var listShallowCategories: Self {
        CommandFactory { request in
            .listShallowCategories(database: request.commandDB)
            .logged(name: "List shallow categories", logger: request.logger)
        }
    }
}
