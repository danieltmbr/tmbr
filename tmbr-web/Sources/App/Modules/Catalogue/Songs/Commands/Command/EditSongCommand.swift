import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

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
