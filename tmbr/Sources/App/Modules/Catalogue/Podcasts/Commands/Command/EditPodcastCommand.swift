import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditPodcastInput {
    
    fileprivate let id: PodcastID
    
    fileprivate let podcast: PodcastInput
    
    init(id: PodcastID, podcast: PodcastInput) {
        self.id = id
        self.podcast = podcast
    }
    
    fileprivate func validate() throws {
        try podcast.validate()
    }
}

struct EditPodcastCommand: Command {
    
    private let configure: PodcastConfiguration
    
    private let database: Database

    private let permission: AuthPermissionResolver<Podcast>
    
    init(
        configure: PodcastConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Podcast>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }
    
    func execute(_ input: EditPodcastInput) async throws -> Podcast {
        guard let podcast = try await Podcast.find(input.id, on: database) else {
            throw Abort(.notFound, reason: "Podcast not found")
        }
        try await permission.grant(podcast)
        try input.validate()
        configure(podcast, with: input.podcast)
        
        try await database.transaction { db in
            try await podcast.save(on: db)
            if podcast.access == .private {
                try await podcast.$podcastNotes.load(on: db, include: \.$note)
                podcast.notes.forEach { $0.access = $0.access && podcast.access }
                try await podcast.notes.update(on: db)
            }
        }
        return podcast
    }
}

extension CommandFactory<EditPodcastInput, Podcast> {
    
    static var editPodcast: Self {
        CommandFactory { request in
            EditPodcastCommand(
                database: request.application.db,
                permission: request.permissions.podcasts.edit
            )
            .logged(logger: request.logger)
        }
    }
}

extension CommandResolver where Input == EditPodcastInput {
    
    func callAsFunction(
        _ podcastID: PodcastID,
        with payload: PodcastPayload
    ) async throws -> Output {
        let input = EditPodcastInput(
            id: podcastID,
            podcast: PodcastInput(payload: payload)
        )
        return try await self.callAsFunction(input)
    }
}
