import Vapor
import WebCore
import TmbrCore

extension CommandFactory<FetchParameters<PlaylistID>, Playlist> {

    static var fetchPlaylist: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.playlists.access,
                writePermission: request.permissions.playlists.edit,
                load: \.$artwork, \.$owner, \.$post, \.$preview,
                then: { playlist, db in
                    try await playlist.preview.$image.load(on: db)
                    try await playlist.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Playlist", logger: request.logger)
        }
    }
}
