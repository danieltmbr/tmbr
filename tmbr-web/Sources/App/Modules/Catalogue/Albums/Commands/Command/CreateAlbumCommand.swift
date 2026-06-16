import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth

struct CreateAlbumCommand: Command {

    private let configure: ModelConfiguration<Album, AlbumInput>

    private let database: Database

    private let permission: AuthPermissionResolver<Void>

    private let validate: Validator<AlbumInput>

    init(
        configure: ModelConfiguration<Album, AlbumInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<AlbumInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }

    func execute(_ input: AlbumInput) async throws -> Album {
        let user = try await permission.grant()
        try validate(input)

        var album = Album(owner: user.userID)
        configure(&album, with: input)
        try await album.save(on: database)

        return album
    }
}

extension CommandFactory<AlbumInput, Album> {

    static var createAlbum: Self {
        CommandFactory { request in
            CreateAlbumCommand(
                configure: .album,
                database: request.commandDB,
                permission: request.permissions.albums.create,
                validate: .album
            )
            .logged(logger: request.logger)
        }
    }
}
