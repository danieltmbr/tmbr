import Foundation
import Vapor
import Core
import Fluent
import AuthKit

struct ImportAlbumTracksInput: Sendable {
    let albumID: AlbumID
    let access: Access
    let artist: String
    let ownerID: UserID
    let tracks: [TrackMetadata]
}

extension Command where Self == PlainCommand<ImportAlbumTracksInput, Void> {
    static func importAlbumTracks(database: Database) -> Self {
        PlainCommand { input in
            for (index, track) in input.tracks.enumerated() {
                var preview = Preview(
                    id: UUID(),
                    parentID: nil,
                    parentAccess: input.access,
                    parentOwner: input.ownerID,
                    parentType: "track"
                )
                preview.primaryInfo = track.name
                preview.secondaryInfo = "by \(input.artist)"
                preview.externalLinks = [track.url].compactMap { $0 }
                try await preview.save(on: database)

                let entry = ContainerEntry(
                    containerType: "album",
                    containerID: input.albumID,
                    previewID: try preview.requireID(),
                    position: index + 1
                )
                try await entry.save(on: database)
            }
        }
    }
}

extension CommandFactory<ImportAlbumTracksInput, Void> {
    static var importAlbumTracks: Self {
        CommandFactory { request in
            .importAlbumTracks(database: request.commandDB)
        }
    }
}
