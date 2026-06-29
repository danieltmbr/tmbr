import Vapor
import WebCore
import TmbrCore

extension CommandFactory<FetchParameters<AlbumID>, Album> {

    static var fetchAlbum: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.albums.access,
                writePermission: request.permissions.albums.edit,
                load: \.$artwork, \.$owner, \.$post, \.$preview,
                then: { album, db in
                    try await album.preview.$image.load(on: db)
                    try await album.preview.$catalogueCategory.load(on: db)
                }
            )
            .logged(name: "Fetch Album", logger: request.logger)
        }
    }
}
