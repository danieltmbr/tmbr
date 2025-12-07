import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

final class FetchPodcastCommand: FetchCommand<Podcast>, @unchecked Sendable {
    
    override func execute(_ params: FetchParameters<FetchCommand<Podcast>.ItemID>) async throws -> Podcast {
        let podcast = try await super.execute(params)
        async let artwork: Void = podcast.$artwork.load(on: database)
        async let notes = podcast.$podcastNotes.load(on: database, include: \.$note)
        async let owner: Void = podcast.$owner.load(on: database)
        async let post: Void = podcast.$post.load(on: database)
        _ = try await (artwork, owner, notes, post)
        return podcast
    }
}

extension CommandFactory<FetchParameters<PodcastID>, Podcast> {
    
    static var fetchPodcast: Self {
        CommandFactory { request in
            FetchPodcastCommand(
                database: request.application.db,
                readPermission: request.permissions.podcasts.access,
                writePermission: request.permissions.podcasts.edit
            )
            .logged(logger: request.logger)
        }
    }
}
