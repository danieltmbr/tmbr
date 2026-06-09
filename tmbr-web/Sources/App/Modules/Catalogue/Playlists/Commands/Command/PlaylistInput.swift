import Foundation
import Vapor
import AuthKit
import Core
import TmbrCore

struct PlaylistInput {

    fileprivate let access: Access

    fileprivate let artwork: ImageID?

    fileprivate let description: String?

    fileprivate let resourceURLs: [String]

    fileprivate let title: String

    let platformCreatedAt: Date?

    let tracks: [TrackMetadata]?

    init(
        access: Access,
        artwork: ImageID?,
        platformCreatedAt: Date? = nil,
        description: String?,
        resourceURLs: [String],
        title: String,
        tracks: [TrackMetadata]? = nil
    ) {
        self.access = access
        self.artwork = artwork
        self.platformCreatedAt = platformCreatedAt
        self.description = description
        self.resourceURLs = resourceURLs
        self.title = title
        self.tracks = tracks
    }

    init(payload: PlaylistPayload) {
        self.init(
            access: payload.access,
            artwork: payload.artwork,
            description: payload.description,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

extension ModelConfiguration where Model == Playlist, Parameters == PlaylistInput {

    static var playlist: Self {
        ModelConfiguration { playlist, input in
            playlist.access = input.access
            playlist.$artwork.id = input.artwork
            if let date = input.platformCreatedAt { playlist.platformCreatedAt = date }
            playlist.description = input.description
            playlist.resourceURLs = input.resourceURLs
            playlist.title = input.title
        }
    }
}

extension Validator where Input == PlaylistInput {

    static var playlist: Self {
        Validator { playlist in
            guard !playlist.title.trimmed.isEmpty else {
                throw Abort(.badRequest, reason: "The playlist title is missing")
            }
        }
    }
}

extension PlaylistInput {

    func edit(id: PlaylistID) -> EditPlaylistInput {
        EditPlaylistInput(id: id, parameters: self)
    }
}
