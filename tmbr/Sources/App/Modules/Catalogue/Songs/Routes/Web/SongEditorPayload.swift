import Foundation
import Vapor
import AuthKit

struct SongEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let album: String?

    let artist: String

    let artworkId: ImageID?

    let genre: String?

    let notes: [String]

    let releaseDate: Date?

    let resourceURLs: [String]

    let title: String

    enum CodingKeys: String, CodingKey {
        case _csrf
        case access
        case album
        case artist
        case artworkId = "artwork-id"
        case genre
        case notes
        case releaseDate = "release-date"
        case resourceURLs
        case title
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self._csrf = try container.decodeIfPresent(String.self, forKey: ._csrf)
        self.access = try container.decode(Access.self, forKey: .access)
        self.album = try container.decodeIfPresent(String.self, forKey: .album)
        self.artist = try container.decode(String.self, forKey: .artist)
        self.artworkId = try container.decodeIfPresent(ImageID.self, forKey: .artworkId)
        self.genre = try container.decodeIfPresent(String.self, forKey: .genre)
        self.releaseDate = try container.decodeIfPresent(Date.self, forKey: .releaseDate)
        self.title = try container.decode(String.self, forKey: .title)

        // Filter out empty notes
        let rawNotes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
        self.notes = rawNotes
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Filter out empty resource URLs
        let urls = try container.decode([String].self, forKey: .resourceURLs)
        self.resourceURLs = urls.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        album: String? = nil,
        artist: String = "",
        artworkId: ImageID? = nil,
        genre: String? = nil,
        notes: [String] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.album = album
        self.artist = artist
        self.artworkId = artworkId
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension SongInput {

    init(payload: SongEditorPayload) {
        self.init(
            access: payload.access,
            album: payload.album,
            artist: payload.artist,
            artwork: payload.artworkId,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            title: payload.title
        )
    }
}

extension NoteInput {

    init(body: String, access: Access) {
        self.init(access: access, body: body)
    }
}
