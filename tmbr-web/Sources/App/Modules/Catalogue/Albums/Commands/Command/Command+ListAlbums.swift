import Foundation
import WebCore
import Fluent
import WebAuth

extension Command where Self == PlainCommand<PageInput, [Album]> {

    static func listAlbums(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Album>>
    ) -> Self {
        PlainCommand { input in
            let query = Album.query(on: database)
                .join(Preview.self, on: \Album.$preview.$id == \Preview.$id)
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

extension CommandFactory<PageInput, [Album]> {

    static var listAlbums: Self {
        CommandFactory { request in
            .listAlbums(database: request.commandDB, permission: request.permissions.albums.query)
            .logged(name: "List albums", logger: request.logger)
        }
    }
}
