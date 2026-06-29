import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import WebAuth

typealias EditPlaylistInput = EditInput<Playlist, PlaylistInput>

extension CommandFactory<EditPlaylistInput, Playlist> {

    static var editPlaylist: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .playlist,
                database: request.commandDB,
                permission: request.permissions.playlists.edit,
                queryNotes: request.commands.notes.query,
                validate: .playlist
            )
            .logged(name: "Edit Playlist Command", logger: request.logger)
        }
    }
}
