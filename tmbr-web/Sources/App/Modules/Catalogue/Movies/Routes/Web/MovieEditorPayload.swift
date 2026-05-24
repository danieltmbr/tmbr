import Foundation
import Vapor
import AuthKit
import TmbrCore

struct MovieEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    private let coverIdRaw: String?

    private let coverSourceURLRaw: String?

    let director: String?

    let genre: String?

    let notes: [NotePayload]

    let releaseDate: Date?

    let resourceURLs: [String]

    let title: String

    var coverId: ImageID? {
        guard let raw = coverIdRaw, !raw.isEmpty else { return nil }
        return Int(raw)
    }

    var coverSourceURL: String? {
        guard let raw = coverSourceURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    var filteredResourceURLs: [String] {
        resourceURLs.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    enum CodingKeys: String, CodingKey {
        case _csrf
        case access
        case coverIdRaw = "cover-id"
        case coverSourceURLRaw = "cover-source-url"
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
        coverIdRaw: String? = nil,
        coverSourceURLRaw: String? = nil,
        director: String? = nil,
        genre: String? = nil,
        notes: [NotePayload] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.coverIdRaw = coverIdRaw
        self.coverSourceURLRaw = coverSourceURLRaw
        self.director = director
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension MovieInput {

    init(payload: MovieEditorPayload, coverId: ImageID? = nil) {
        self.init(
            access: payload.access,
            cover: coverId ?? payload.coverId,
            director: payload.director,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.filteredResourceURLs,
            title: payload.title
        )
    }
}
