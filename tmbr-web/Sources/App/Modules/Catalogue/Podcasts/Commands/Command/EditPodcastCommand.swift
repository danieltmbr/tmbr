import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

typealias EditPodcastInput = EditInput<Podcast, PodcastInput>

extension CommandFactory<EditPodcastInput, Podcast> {
    
    static var editPodcast: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .podcast,
                database: request.commandDB,
                permission: request.permissions.podcasts.edit,
                queryNotes: request.commands.notes.query,
                validate: .podcast
            )
            .logged(name: "Edit Podcast Command", logger: request.logger)
        }
    }
}
