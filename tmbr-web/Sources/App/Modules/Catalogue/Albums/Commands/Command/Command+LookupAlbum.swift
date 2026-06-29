import Foundation
import WebCore
import Fluent
import WebAuth

extension Command where Self == PlainCommand<String, Album?> {

    static func lookupAlbum(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Album>>
    ) -> Self {
        PlainCommand { url in
            let escaped = url.replacingOccurrences(of: "'", with: "''")
            let query = Album.query(on: database)
                .filter(.sql(unsafeRaw: "'\(escaped)' = ANY(albums.resource_urls)"))
            try await permission.grant(query)
            return try await query.first()
        }
    }
}

extension CommandFactory<String, Album?> {

    static var lookupAlbum: Self {
        CommandFactory { request in
            .lookupAlbum(
                database: request.commandDB,
                permission: request.permissions.albums.lookup
            )
            .logged(name: "Lookup Album", logger: request.logger)
        }
    }
}
