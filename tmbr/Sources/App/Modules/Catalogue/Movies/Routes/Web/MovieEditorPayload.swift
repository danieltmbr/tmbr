import Foundation
import Vapor
import AuthKit

struct MovieEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    private let artworkIdRaw: String?

    private let artworkSourceURLRaw: String?

    let director: String?

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
        case artworkIdRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case director
        case genre
        case notes
        case releaseDate = "release-date"
        case resourceURLs
        case title
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        artworkIdRaw: String? = nil,
        artworkSourceURLRaw: String? = nil,
        director: String? = nil,
        genre: String? = nil,
        notes: [NotePayload] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.artworkIdRaw = artworkIdRaw
        self.artworkSourceURLRaw = artworkSourceURLRaw
        self.director = director
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension MovieInput {

    init(payload: MovieEditorPayload, artworkId: ImageID? = nil) {
        self.init(
            access: payload.access,
            cover: artworkId ?? payload.artworkId,
            director: payload.director,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.filteredResourceURLs,
            title: payload.title
        )
    }
}
