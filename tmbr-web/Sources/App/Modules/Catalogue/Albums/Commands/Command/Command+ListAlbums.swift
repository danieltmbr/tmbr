import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Album]> {

    static func listAlbums(database: Database, permission: AuthPermissionResolver<Void>) -> Self {
        PlainCommand { input in
            let user = try await permission.grant()
            var query = Album.query(on: database)
                .filter(\.$owner.$id == user.userID)
                .join(Preview.self, on: \Album.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image) }
                .with(\.$artwork)
                .with(\.$owner)
                .with(\.$post)

            if let since = input.since {
                query = query.filter(Preview.self, \Preview.$createdAt > since)
            }
            if let before = input.before {
                query = query.filter(Preview.self, \Preview.$createdAt < before)
            }

            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListCatalogueItemInput, [Album]> {

    static var listAlbums: Self {
        CommandFactory { request in
            .listAlbums(database: request.commandDB, permission: request.permissions.albums.list)
            .logged(name: "List albums", logger: request.logger)
        }
    }
}
