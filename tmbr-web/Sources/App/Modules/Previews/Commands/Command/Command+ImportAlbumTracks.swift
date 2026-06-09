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

struct ImportAlbumTracksCommand: Command {

    typealias Input = ImportAlbumTracksInput
    typealias Output = Void

    private let findCategory: CommandResolver<String, CatalogueCategory>
    private let findSongPreviewsByURL: CommandResolver<FindSongPreviewsByURLInput, [String: Preview]>
    private let database: Database

    init(
        findCategory: CommandResolver<String, CatalogueCategory>,
        findSongPreviewsByURL: CommandResolver<FindSongPreviewsByURLInput, [String: Preview]>,
        database: Database
    ) {
        self.findCategory = findCategory
        self.findSongPreviewsByURL = findSongPreviewsByURL
        self.database = database
    }

    func execute(_ input: ImportAlbumTracksInput) async throws {
        let categoryID = try await findCategory("track").requireID()

        let trackURLs = input.tracks.compactMap(\.url)
        let existingByURL = try await findSongPreviewsByURL(FindSongPreviewsByURLInput(ownerID: input.ownerID, urls: trackURLs))

        for (index, track) in input.tracks.enumerated() {
            let previewID: UUID
            if let url = track.url, let existing = existingByURL[url] {
                previewID = try existing.requireID()
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

extension CommandFactory<ImportAlbumTracksInput, Void> {
    static var importAlbumTracks: Self {
        CommandFactory { request in
            ImportAlbumTracksCommand(
                findCategory: request.commands.catalogueCategories.find,
                findSongPreviewsByURL: request.commands.previews.findSongPreviewsByURL,
                database: request.commandDB
            )
        }
    }
}
