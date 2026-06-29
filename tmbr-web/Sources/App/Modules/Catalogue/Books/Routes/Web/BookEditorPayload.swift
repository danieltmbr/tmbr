import Foundation
import Vapor
import WebAuth
import TmbrCore

struct BookEditorPayload: Decodable, Sendable {

    let _csrf: String?

    let access: Access

    let author: String

    private let coverIdRaw: String?

    private let coverSourceURLRaw: String?

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
        case author
        case coverIdRaw = "cover-id"
        case coverSourceURLRaw = "cover-source-url"
        case genre
        case notes
        case releaseDate = "release-date"
        case resourceURLs
        case title
    }

    init(
        _csrf: String? = nil,
        access: Access = .private,
        author: String = "",
        coverIdRaw: String? = nil,
        coverSourceURLRaw: String? = nil,
        genre: String? = nil,
        notes: [NotePayload] = [],
        releaseDate: Date? = nil,
        resourceURLs: [String] = [],
        title: String = ""
    ) {
        self._csrf = _csrf
        self.access = access
        self.author = author
        self.coverIdRaw = coverIdRaw
        self.coverSourceURLRaw = coverSourceURLRaw
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.title = title
    }
}

extension BookInput {

    init(payload: BookEditorPayload, coverId: ImageID? = nil) {
        self.init(
            access: payload.access,
            author: payload.author,
            cover: coverId ?? payload.coverId,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.filteredResourceURLs,
            title: payload.title
        )
    }
}
