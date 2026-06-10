import Foundation
import Core
import Fluent

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Album]> {

    static func listAlbums(database: Database) -> Self {
        PlainCommand { input in
            var query = Album.query(on: database)
                .filter(\.$owner.$id == input.ownerID)
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
            .listAlbums(database: request.commandDB)
            .logged(name: "List albums", logger: request.logger)
        }
    }
}
