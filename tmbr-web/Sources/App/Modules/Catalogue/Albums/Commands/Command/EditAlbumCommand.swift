import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

typealias EditAlbumInput = EditInput<Album, AlbumInput>

extension CommandFactory<EditAlbumInput, Album> {

    static var editAlbum: Self {
        CommandFactory { request in
            PlainCommand.edit(
                configure: .album,
                database: request.commandDB,
                permission: request.permissions.albums.edit,
                queryNotes: request.commands.notes.query,
                validate: .album
            )
            .logged(name: "Edit Album Command", logger: request.logger)
        }
    }
}
