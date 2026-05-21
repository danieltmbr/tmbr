import Foundation
import Vapor
import AuthKit

struct AlbumEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let artist: String

    private let artworkIdRaw: String?

    private let artworkSourceURLRaw: String?

    let genre: String?

    let notes: [NotePayload]

    let releaseDate: Date?

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

    var filteredResourceURLs: [String] {
        resourceURLs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case _csrf
        case access
        case artist
        case artworkIdRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case genre
        case notes
        case releaseDate = "release-date"
        case resourceURLs
        case title
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        artist: String = "",
        artworkIdRaw: String? = nil,
        artworkSourceURLRaw: String? = nil,
        genre: String? = nil,
        notes: [NotePayload] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.artist = artist
        self.artworkIdRaw = artworkIdRaw
        self.artworkSourceURLRaw = artworkSourceURLRaw
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension AlbumInput {

    init(payload: AlbumEditorPayload, artworkId: ImageID? = nil) {
        self.init(
            access: payload.access,
            artist: payload.artist,
            artwork: artworkId ?? payload.artworkId,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.filteredResourceURLs,
            title: payload.title
        )
    }
}
