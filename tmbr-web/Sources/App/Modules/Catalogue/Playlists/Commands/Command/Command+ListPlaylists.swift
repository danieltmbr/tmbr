import Foundation
import Core
import Fluent

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Playlist]> {

    static func listPlaylists(database: Database) -> Self {
        PlainCommand { input in
            var query = Playlist.query(on: database)
                .filter(\.$owner.$id == input.ownerID)
                .join(Preview.self, on: \Playlist.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Playlist]> {

    static var listPlaylists: Self {
        CommandFactory { request in
            .listPlaylists(database: request.commandDB)
            .logged(name: "List playlists", logger: request.logger)
        }
    }
}
