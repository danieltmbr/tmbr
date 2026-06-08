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
            guard let trackCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == "track").first(),
                  let categoryID = trackCategory.id else {
                throw Abort(.internalServerError, reason: "Track category not found in catalogue_categories")
            }

            let findCmd: PlainCommand<FindSongPreviewsByURLInput, [String: PreviewID]> = .findSongPreviewsByURL(database: database)
            let existingByURL = try await findCmd(FindSongPreviewsByURLInput(ownerID: input.ownerID))

            for (index, track) in input.tracks.enumerated() {
                let previewID: UUID
                if let url = track.url, let existing = existingByURL[url] {
                    previewID = existing
                } else {
                    let preview = Preview(
                        id: UUID(),
                        parentID: nil,
                        parentAccess: input.access,
                        parentOwner: input.ownerID,
                        categoryID: categoryID
                    )
                    preview.primaryInfo = track.name
                    if let artist = input.artist {
                        preview.secondaryInfo = "by \(artist)"
                    }
                    preview.externalLinks = [track.url].compactMap { $0 }
                    try await preview.save(on: database)
                    previewID = try preview.requireID()
                }

                let entry = ContainerEntry(
                    containerType: input.containerType,
                    containerID: input.albumID,
                    previewID: previewID,
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
