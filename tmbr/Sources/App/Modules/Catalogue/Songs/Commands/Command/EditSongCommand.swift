import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditSongInput {
    
    fileprivate let id: SongID
    
    fileprivate let song: SongInput
    
    init(id: SongID, song: SongInput) {
        self.id = id
        self.song = song
    }
    
    fileprivate func validate() throws {
        try song.validate()
    }
}

struct EditSongCommand: Command {
    
    private let configure: SongConfiguration
    
    private let database: Database

    private let permission: AuthPermissionResolver<Song>
    
    init(
        configure: SongConfiguration = .default,
        database: Database,
        permission: AuthPermissionResolver<Song>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
    }
    
    func execute(_ input: EditSongInput) async throws -> Song {
        guard let song = try await Song.find(input.id, on: database) else {
            throw Abort(.notFound, reason: "Song not found")
        }
        try await permission.grant(song)
        try input.validate()
        configure(song, with: input.song)
        
        try await database.transaction { db in
            try await song.save(on: db)
            if song.access == .private {
                try await song.$songNotes.load(on: db, include: \.$note)
                song.notes.forEach { $0.access = $0.access && song.access }
                try await song.notes.update(on: db)
            }
        }
        return song
    }
}

extension CommandFactory<EditSongInput, Song> {
    
    static var editSong: Self {
        CommandFactory { request in
            EditSongCommand(
                database: request.commandDB,
                permission: request.permissions.songs.edit
            )
            .logged(logger: request.logger)
        }
    }
}

extension CommandResolver where Input == EditSongInput {
    
    func callAsFunction(
        _ songID: SongID,
        with payload: SongPayload
    ) async throws -> Output {
        let input = EditSongInput(
            id: songID,
            song: SongInput(payload: payload)
        )
        return try await self.callAsFunction(input)
    }
}
