import Foundation
import Core
import Fluent
import AuthKit

extension Command where Self == PlainCommand<ListCatalogueItemInput, [Podcast]> {

    static func listPodcasts(database: Database, permission: BasePermissionResolver<QueryBuilder<Podcast>>) -> Self {
        PlainCommand { input in
            let query = Podcast.query(on: database)
                .join(Preview.self, on: \Podcast.$preview.$id == \Preview.$id)
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

extension CommandFactory<ListCatalogueItemInput, [Podcast]> {

    static var listPodcasts: Self {
        CommandFactory { request in
            .listPodcasts(database: request.commandDB, permission: request.permissions.podcasts.list)
            .logged(name: "List podcasts", logger: request.logger)
        }
    }
}
