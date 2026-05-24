import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct CreatePlaylistCommand: Command {

    private let configure: ModelConfiguration<Playlist, PlaylistInput>

    private let database: Database

    private let permission: AuthPermissionResolver<Void>

    private let validate: Validator<PlaylistInput>

    init(
        configure: ModelConfiguration<Playlist, PlaylistInput>,
        database: Database,
        permission: AuthPermissionResolver<Void>,
        validate: Validator<PlaylistInput>
    ) {
        self.configure = configure
        self.database = database
        self.permission = permission
        self.validate = validate
    }

    func execute(_ input: PlaylistInput) async throws -> Playlist {
        let user = try await permission.grant()
        try validate(input)

        var playlist = Playlist(owner: user.userID)
        configure(&playlist, with: input)
        try await playlist.save(on: database)

        return playlist
    }
}

extension CommandFactory<PlaylistInput, Playlist> {

    static var createPlaylist: Self {
        CommandFactory { request in
            CreatePlaylistCommand(
                configure: .playlist,
                database: request.commandDB,
                permission: request.permissions.playlists.create,
                validate: .playlist
            )
            .logged(logger: request.logger)
        }
    }
}
