import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreatePodcastInput {
    struct Note {
        fileprivate let access: Access
        
        fileprivate let body: String
        
        init(payload: NotePayload) {
            access = payload.access
            body = payload.body
        }
        
        fileprivate func validate() throws {
            guard !body.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "Note's content is missing.")
            }
        }
    }
    
    fileprivate let podcast: PodcastInput
    
    fileprivate let notes: [Note]
    
    init(payload: PodcastPayload) {
        podcast = PodcastInput(payload: payload)
        notes = payload.notes?.map(Note.init) ?? []
    }
    
    fileprivate func validate() throws {
        try podcast.validate()
        try notes.forEach { try $0.validate() }
    }
}

struct CreatePodcastCommand: Command {
    
    typealias Input = CreatePodcastInput
    
    typealias Output = Podcast
    
    private let configure: PodcastConfiguration

    private let database: Database
        
    private let permission: AuthPermissionResolver<Void>

    init(
        configure: PodcastConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Void>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }

    func execute(_ input: CreatePodcastInput) async throws -> Podcast {
        let user = try await permission.grant()
        try input.validate()
        return try await database.transaction { db in
            let podcast = Podcast(owner: user.userID)
            configure(podcast, with: input.podcast)
            try await podcast.save(on: database)
            
            let podcastID = try podcast.requireID()
            let previewID = try podcast.preview.requireID()
            let notes = input.notes.map { note in
                Note(
                    attachmentID: previewID,
                    authorID: user.userID,
                    access: note.access && podcast.access,
                    body: note.body
                )
            }
            try await notes.create(on: db)
            
            let podcastNotes = try notes.map { note in
                PodcastNote(note: try note.requireID(), podcast: podcastID)
            }
            try await podcastNotes.create(on: db)
            try await podcast.$podcastNotes.load(on: db, include: \.$note)
            return podcast
        }
    }
}

extension CommandFactory<CreatePodcastInput, Podcast> {

    static var createPodcast: Self {
        CommandFactory { request in
            CreatePodcastCommand(
                database: request.application.db,
                permission: request.permissions.podcasts.create
            )
            .logged(logger: request.logger)
        }
    }
}
