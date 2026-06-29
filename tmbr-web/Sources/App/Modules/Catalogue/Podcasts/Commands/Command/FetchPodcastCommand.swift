import Vapor
import WebCore
import TmbrCore

extension CommandFactory<FetchParameters<PodcastID>, Podcast> {
    
    static var fetchPodcast: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.podcasts.access,
                writePermission: request.permissions.podcasts.edit,
                load: \.$artwork, \.$owner, \.$post, \.$preview,
                then: { podcast, db in
                    try await podcast.preview.$image.load(on: db)
                    try await podcast.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Podcast", logger: request.logger)
        }
    }
}
