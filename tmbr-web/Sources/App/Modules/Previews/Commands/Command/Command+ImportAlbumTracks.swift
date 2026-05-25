import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct ImportAlbumTracksInput: Sendable {
    let albumID: Int
    let access: Access
    let artist: String?
    let ownerID: UserID
    let tracks: [TrackMetadata]
    let containerType: String

    init(
        albumID: Int,
        access: Access,
        artist: String?,
        ownerID: UserID,
        tracks: [TrackMetadata],
        containerType: String = "album"
    ) {
        self.albumID = albumID
        self.access = access
        self.artist = artist
        self.ownerID = ownerID
        self.tracks = tracks
        self.containerType = containerType
    }
}

extension Command where Self == PlainCommand<ImportAlbumTracksInput, Void> {
    static func importAlbumTracks(database: Database) -> Self {
        PlainCommand { input in
            for (index, track) in input.tracks.enumerated() {
                let preview = Preview(
                    id: UUID(),
                    parentID: nil,
                    parentAccess: input.access,
                    parentOwner: input.ownerID,
                    parentType: "track"
                )
                preview.primaryInfo = track.name
                if let artist = input.artist {
                    preview.secondaryInfo = "by \(artist)"
                }
                preview.externalLinks = [track.url].compactMap { $0 }
                try await preview.save(on: database)

                let entry = ContainerEntry(
                    containerType: input.containerType,
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
