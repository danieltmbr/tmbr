import Foundation
import CoreWeb
import Fluent
import CoreAuth

extension Command where Self == PlainCommand<PageInput, [Podcast]> {

    static func listPodcasts(database: Database, permission: BasePermissionResolver<QueryBuilder<Podcast>>) -> Self {
        PlainCommand { input in
            let query = Podcast.query(on: database)
                .join(Preview.self, on: \Podcast.$preview.$id == \Preview.$id)
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

extension CommandFactory<PageInput, [Podcast]> {

    static var listPodcasts: Self {
        CommandFactory { request in
            .listPodcasts(database: request.commandDB, permission: request.permissions.podcasts.query)
            .logged(name: "List podcasts", logger: request.logger)
        }
    }
}
