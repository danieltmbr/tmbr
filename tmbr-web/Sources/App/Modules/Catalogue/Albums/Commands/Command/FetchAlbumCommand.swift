import Vapor
import CoreWeb
import CoreTmbr

extension CommandFactory<FetchParameters<AlbumID>, Album> {

    static var fetchAlbum: Self {
        CommandFactory { request in
            PlainCommand.fetch(
                database: request.commandDB,
                readPermission: request.permissions.albums.access,
                writePermission: request.permissions.albums.edit,
                load: \.$artwork, \.$owner, \.$post
            )
            .logged(name: "Fetch Album", logger: request.logger)
        }
    }
}
