import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<PageInput, [Playlist]> {

    static func listPlaylists(database: Database, permission: BasePermissionResolver<QueryBuilder<Playlist>>) -> Self {
        PlainCommand { input in
            let query = Playlist.query(on: database)
                .join(Preview.self, on: \Playlist.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image) }
                .with(\.$artwork)
                .with(\.$owner)
                .with(\.$post)
            query.page(input)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PageInput, [Playlist]> {

    static var listPlaylists: Self {
        CommandFactory { request in
            .listPlaylists(database: request.commandDB, permission: request.permissions.playlists.query)
            .logged(name: "List playlists", logger: request.logger)
        }
    }
}
