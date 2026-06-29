import Vapor
import WebCore
import TmbrCore

extension CommandFactory<FetchParameters<SongID>, Song> {
    
    static var fetchSong: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.songs.access,
                writePermission: request.permissions.songs.edit,
                load: \.$artwork, \.$owner, \.$post, \.$preview,
                then: { song, db in
                    try await song.preview.$image.load(on: db)
                    try await song.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Song", logger: request.logger)
        }
    }
}
