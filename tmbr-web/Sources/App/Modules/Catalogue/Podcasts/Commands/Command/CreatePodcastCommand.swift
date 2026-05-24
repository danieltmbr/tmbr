import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreatePodcastCommand: Command {
    
    private let configure: ModelConfiguration<Podcast, PodcastInput>
    
    private let database: Database
    
    private let permission: AuthPermissionResolver<Void>
    
    private let validate: Validator<PodcastInput>
    
    init(
        configure: ModelConfiguration<Podcast, PodcastInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<PodcastInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }
    
    func execute(_ input: PodcastInput) async throws -> Podcast {
        let user = try await permission.grant()
        try validate(input)
        
        var podcast = Podcast(owner: user.userID)
        configure(&podcast, with: input)
        try await podcast.save(on: database)
        
        return podcast
    }
}

extension CommandFactory<PodcastInput, Podcast> {
    
    static var createPodcast: Self {
        CommandFactory { request in
            CreatePodcastCommand(
                configure: .podcast,
                database: request.commandDB,
                permission: request.permissions.podcasts.create,
                validate: .podcast
            )
            .logged(logger: request.logger)
        }
    }
}
