import Foundation
import WebCore
import Fluent
import WebAuth

extension Command where Self == PlainCommand<String, Podcast?> {

    static func lookupPodcast(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Podcast>>
    ) -> Self {
        PlainCommand { url in
            let escaped = url.replacingOccurrences(of: "'", with: "''")
            let query = Podcast.query(on: database)
                .filter(.sql(unsafeRaw: "'\(escaped)' = ANY(podcasts.resource_urls)"))
            try await permission.grant(query)
            return try await query.first()
        }
    }
}

extension CommandFactory<String, Podcast?> {

    static var lookupPodcast: Self {
        CommandFactory { request in
            .lookupPodcast(
                database: request.commandDB,
                permission: request.permissions.podcasts.lookup
            )
            .logged(name: "Lookup Podcast", logger: request.logger)
        }
    }
}
