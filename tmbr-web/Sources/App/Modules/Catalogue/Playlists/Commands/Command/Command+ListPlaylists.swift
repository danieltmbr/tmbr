import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Playlist]> {

    static func listPlaylists(database: Database, permission: BasePermissionResolver<QueryBuilder<Playlist>>) -> Self {
        PlainCommand { input in
            let query = Playlist.query(on: database)
                .join(Preview.self, on: \Playlist.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Playlist]> {

    static var listPlaylists: Self {
        CommandFactory { request in
            .listPlaylists(database: request.commandDB, permission: request.permissions.playlists.list)
            .logged(name: "List playlists", logger: request.logger)
        }
    }
}
