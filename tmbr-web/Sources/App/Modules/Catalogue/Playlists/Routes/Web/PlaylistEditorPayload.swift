import Foundation
import Vapor
import AuthKit
import TmbrCore

struct PlaylistEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    private let artworkIdRaw: String?

    private let artworkSourceURLRaw: String?

    private let artworkFallbackURLRaw: String?

    private let platformCreatedAtRaw: String?

    let description: String?

    let notes: [NotePayload]

    private let tracklistJSONRaw: String?

    let resourceURLs: [String]

    let title: String

    var artworkId: ImageID? {
        guard let raw = artworkIdRaw, !raw.isEmpty else { return nil }
        return Int(raw)
    }

    var artworkSourceURL: String? {
        guard let raw = artworkSourceURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    var artworkFallbackURL: String? {
        guard let raw = artworkFallbackURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    var platformCreatedAt: Date? {
        guard let raw = platformCreatedAtRaw, !raw.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    var filteredResourceURLs: [String] {
        resourceURLs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var tracks: [TrackMetadata]? {
        guard let raw = tracklistJSONRaw, !raw.isEmpty,
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([TrackMetadata].self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case _csrf
        case access
        case artworkIdRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case artworkFallbackURLRaw = "artwork-fallback-url"
        case platformCreatedAtRaw = "platform-created-at"
        case description
        case notes
        case tracklistJSONRaw = "tracklist-json"
        case resourceURLs
        case title
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        artworkIdRaw: String? = nil,
        artworkSourceURLRaw: String? = nil,
        artworkFallbackURLRaw: String? = nil,
        platformCreatedAtRaw: String? = nil,
        description: String? = nil,
        notes: [NotePayload] = [],
        tracklistJSONRaw: String? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.artworkIdRaw = artworkIdRaw
        self.artworkSourceURLRaw = artworkSourceURLRaw
        self.artworkFallbackURLRaw = artworkFallbackURLRaw
        self.platformCreatedAtRaw = platformCreatedAtRaw
        self.description = description
        self.notes = notes
        self.tracklistJSONRaw = tracklistJSONRaw
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension PlaylistInput {

    init(payload: PlaylistEditorPayload, artworkId: ImageID? = nil) {
        self.init(
            access: payload.access,
            artwork: artworkId ?? payload.artworkId,
            platformCreatedAt: payload.platformCreatedAt,
            description: payload.description,
            resourceURLs: payload.filteredResourceURLs,
            title: payload.title,
            tracks: payload.tracks
        )
    }
}
