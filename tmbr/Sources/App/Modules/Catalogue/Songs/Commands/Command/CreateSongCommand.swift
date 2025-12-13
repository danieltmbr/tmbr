import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreateSongCommand: Command {
    
    private let configure: ModelConfiguration<Song, SongInput>
    
    private let database: Database
    
    private let permission: AuthPermissionResolver<Void>
    
    private let validate: Validator<SongInput>
    
    init(
        configure: ModelConfiguration<Song, SongInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<SongInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }
    
    func execute(_ input: SongInput) async throws -> Song {
        let user = try await permission.grant()
        try validate(input)
        
        var song = Song(owner: user.userID)
        configure(&song, with: input)
        try await song.save(on: database)
        
        return song
    }
}

extension CommandFactory<SongInput, Song> {
    
    static var createSong: Self {
        CommandFactory { request in
            CreateSongCommand(
                configure: .song,
                database: request.commandDB,
                permission: request.permissions.songs.create,
                validate: .song
            )
            .logged(logger: request.logger)
        }
    }
}
