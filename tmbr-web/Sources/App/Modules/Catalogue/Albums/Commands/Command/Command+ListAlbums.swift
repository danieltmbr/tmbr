import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Album]> {

    static func listAlbums(database: Database, permission: BasePermissionResolver<QueryBuilder<Album>>) -> Self {
        PlainCommand { input in
            let query = Album.query(on: database)
                .join(Preview.self, on: \Album.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image) }
                .with(\.$artwork)
                .with(\.$owner)
                .with(\.$post)
            if let since = input.since { query.filter(Preview.self, \Preview.$createdAt > since) }
            if let before = input.before { query.filter(Preview.self, \Preview.$createdAt < before) }
            try await permission.grant(query)
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
