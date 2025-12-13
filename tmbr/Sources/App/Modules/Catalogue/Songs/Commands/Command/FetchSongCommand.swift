import Vapor
import Core

extension CommandFactory<FetchParameters<SongID>, Song> {
    
    static var fetchSong: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.songs.access,
                writePermission: request.permissions.songs.edit,
                load: \.$artwork, \.$owner, \.$post
            )
            .logged(name: "Fetch Song", logger: request.logger)
        }
    }
}
