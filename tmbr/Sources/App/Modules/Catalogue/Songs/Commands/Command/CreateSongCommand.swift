import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateSongInput {
    
    fileprivate let song: SongInput
    
    fileprivate let notes: [NoteInput]
    
    init(payload: SongPayload) {
        song = SongInput(payload: payload)
        notes = payload.notes?.map(NoteInput.init) ?? []
    }
    
    fileprivate func validate() throws {
        try song.validate()
        try notes.forEach { try $0.validate() }
    }
}

struct CreateSongCommand: Command {
    
    typealias Input = CreateSongInput
    
    typealias Output = Song
    
    private let configure: SongConfiguration

    private let database: Database
        
    private let permission: AuthPermissionResolver<Void>

    init(
        configure: SongConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Void>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }

    func execute(_ input: CreateSongInput) async throws -> Song {
        let user = try await permission.grant()
        try input.validate()
        return try await database.transaction { db in
            let song = Song(owner: user.userID)
            configure(song, with: input.song)
            try await song.save(on: database)
            
            let songID = try song.requireID()
            let previewID = try song.preview.requireID()
            let notes = input.notes.map { note in
                Note(
                    attachmentID: previewID,
                    authorID: user.userID,
                    access: note.access && song.access,
                    body: note.body
                )
            }
            try await notes.create(on: db)
            
            let songNotes = try notes.map { note in
                SongNote(note: try note.requireID(), song: songID)
            }
            try await songNotes.create(on: db)
            try await song.$songNotes.load(on: db, include: \.$note)
            return song
        }
    }
}

extension CommandFactory<CreateSongInput, Song> {

    static var createSong: Self {
        CommandFactory { request in
            CreateSongCommand(
                database: request.application.db,
                permission: request.permissions.songs.create
            )
            .logged(logger: request.logger)
        }
    }
}
