import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<String, Song?> {

    static func lookupSong(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Song>>
    ) -> Self {
        PlainCommand { url in
            let escaped = url.replacingOccurrences(of: "'", with: "''")
            let query = Song.query(on: database)
                .filter(.sql(unsafeRaw: "'\(escaped)' = ANY(songs.resource_urls)"))
            try await permission.grant(query)
            return try await query.first()
        }
    }
}

extension CommandFactory<String, Song?> {

    static var lookupSong: Self {
        CommandFactory { request in
            .lookupSong(
                database: request.commandDB,
                permission: request.permissions.songs.lookup
            )
            .logged(name: "Lookup Song", logger: request.logger)
        }
    }
}
