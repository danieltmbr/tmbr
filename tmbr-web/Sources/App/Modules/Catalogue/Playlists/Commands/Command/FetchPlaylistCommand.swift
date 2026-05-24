import Vapor
import Core

extension CommandFactory<FetchParameters<PlaylistID>, Playlist> {

    static var fetchPlaylist: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.playlists.access,
                writePermission: request.permissions.playlists.edit,
                load: \.$artwork, \.$owner, \.$post
            )
            .logged(name: "Fetch Playlist", logger: request.logger)
        }
    }
}
