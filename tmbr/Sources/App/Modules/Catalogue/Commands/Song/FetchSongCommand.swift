import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

final class FetchSongCommand: FetchCommand<Song>, @unchecked Sendable {
    
    override func execute(_ params: FetchParameters<FetchCommand<Song>.ItemID>) async throws -> Song {
        let song = try await super.execute(params)
        async let artwork: Void = song.$artwork.load(on: database)
        async let notes = song.$songNotes.load(on: database, include: \.$note)
        async let owner: Void = song.$owner.load(on: database)
        async let post: Void = song.$post.load(on: database)
        _ = try await (artwork, owner, notes, post)
        return song
    }
}

extension CommandFactory<FetchParameters<SongID>, Song> {
    
    static var fetchSong: Self {
        CommandFactory { request in
            FetchSongCommand(
                database: request.application.db,
                readPermission: request.permissions.songs.access,
                writePermission: request.permissions.songs.edit
            )
            .logged(logger: request.logger)
        }
    }
}
