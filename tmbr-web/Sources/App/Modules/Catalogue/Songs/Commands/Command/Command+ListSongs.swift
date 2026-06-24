import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<PageInput, [Song]> {

    static func listSongs(database: Database, permission: BasePermissionResolver<QueryBuilder<Song>>) -> Self {
        PlainCommand { input in
            let query = Song.query(on: database)
                .join(Preview.self, on: \Song.$preview.$id == \Preview.$id)
                .sort(Preview.self, \Preview.$createdAt, .descending)
                .with(\.$preview) { p in p.with(\.$image).with(\.$catalogueCategory) }
                .with(\.$artwork)
                .with(\.$owner)
                .with(\.$post)
            query.page(input)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PageInput, [Song]> {

    static var listSongs: Self {
        CommandFactory { request in
            .listSongs(database: request.commandDB, permission: request.permissions.songs.query)
            .logged(name: "List songs", logger: request.logger)
        }
    }
}
