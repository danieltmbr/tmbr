import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth

typealias EditSongInput = EditInput<Song, SongInput>

extension CommandFactory<EditSongInput, Song> {
    
    static var editSong: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .song,
                database: request.commandDB,
                permission: request.permissions.songs.edit,
                queryNotes: request.commands.notes.query,
                validate: .song
            )
            .logged(name: "Edit Song Command", logger: request.logger)
        }
    }
}
