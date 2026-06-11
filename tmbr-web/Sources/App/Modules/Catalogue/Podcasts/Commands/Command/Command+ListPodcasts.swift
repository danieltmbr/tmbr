import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Podcast]> {

    static func listPodcasts(database: Database, permission: AuthPermissionResolver<Void>) -> Self {
        PlainCommand { input in
            let user = try await permission.grant()
            var query = Podcast.query(on: database)
                .filter(\.$owner.$id == user.userID)
                .join(Preview.self, on: \Podcast.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Podcast]> {

    static var listPodcasts: Self {
        CommandFactory { request in
            .listPodcasts(database: request.commandDB, permission: request.permissions.podcasts.list)
            .logged(name: "List podcasts", logger: request.logger)
        }
    }
}
