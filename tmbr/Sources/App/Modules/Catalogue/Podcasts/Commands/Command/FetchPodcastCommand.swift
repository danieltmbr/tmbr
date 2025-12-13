import Vapor
import Core

extension CommandFactory<FetchParameters<PodcastID>, Podcast> {
    
    static var fetchPodcast: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.podcasts.access,
                writePermission: request.permissions.podcasts.edit,
                load: \.$artwork, \.$owner, \.$post
            )
            .logged(name: "Fetch Podcast", logger: request.logger)
        }
    }
}
