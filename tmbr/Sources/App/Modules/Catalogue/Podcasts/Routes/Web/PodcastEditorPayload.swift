import Foundation
import Vapor
import AuthKit

struct PodcastEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let episodeTitle: String

    private let artworkIdRaw: String?

    private let artworkSourceURLRaw: String?

    let episodeNumber: Int?

    let genre: String?

    let notes: [NotePayload]

    let releaseDate: Date?

    let resourceURLs: [String]

    let seasonNumber: Int?

    let title: String

    var artworkId: ImageID? {
        guard let raw = artworkIdRaw, !raw.isEmpty else { return nil }
        return Int(raw)
    }

    var artworkSourceURL: String? {
        guard let raw = artworkSourceURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    var filteredResourceURLs: [String] {
        resourceURLs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case _csrf
        case access
        case artworkIdRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case episodeNumber = "episode-number"
        case episodeTitle
        case genre
        case notes
        case releaseDate = "release-date"
        case resourceURLs
        case seasonNumber = "season-number"
        case title
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        artworkIdRaw: String? = nil,
        artworkSourceURLRaw: String? = nil,
        episodeNumber: Int? = nil,
        episodeTitle: String = "",
        genre: String? = nil,
        notes: [NotePayload] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        seasonNumber: Int? = nil,
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.artworkIdRaw = artworkIdRaw
        self.artworkSourceURLRaw = artworkSourceURLRaw
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.seasonNumber = seasonNumber
        self.title = title
    }
}

extension PodcastInput {

    init(payload: PodcastEditorPayload, artworkId: ImageID? = nil) {
        self.init(
            access: payload.access,
            artwork: artworkId ?? payload.artworkId,
            episodeNumber: payload.episodeNumber,
            episodeTitle: payload.episodeTitle,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.filteredResourceURLs,
            seasonNumber: payload.seasonNumber,
            title: payload.title
        )
    }
}
