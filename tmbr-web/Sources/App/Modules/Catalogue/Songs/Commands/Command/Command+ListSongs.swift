import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Song]> {

    static func listSongs(database: Database, permission: BasePermissionResolver<QueryBuilder<Song>>) -> Self {
        PlainCommand { input in
            let query = Song.query(on: database)
                .join(Preview.self, on: \Song.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Song]> {

    static var listSongs: Self {
        CommandFactory { request in
            .listSongs(database: request.commandDB, permission: request.permissions.songs.query)
            .logged(name: "List songs", logger: request.logger)
        }
    }
}
