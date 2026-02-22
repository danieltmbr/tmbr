import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct SongEditorViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let body: String
        let access: Access
    }

    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let album: String

    private let artist: String

    private let artworkId: Int?

    private let artworkURL: String?

    private let artworkThumbnailURL: String?

    private let genre: String

    private let notes: [NoteViewModel]

    private let releaseDate: String

    private let resourceURLs: [String]

    private let submit: Form.Submit

    private let title: String

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String? = nil,
        access: Access = .private,
        album: String = "",
        artist: String = "",
        artworkId: Int? = nil,
        artworkURL: String? = nil,
        artworkThumbnailURL: String? = nil,
        genre: String = "",
        notes: [NoteViewModel] = [],
        releaseDate: String = "",
        resourceURLs: [String] = [],
        submit: Form.Submit,
        title: String = "",
        csrf: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.access = access
        self.album = album
        self.artist = artist
        self.artworkId = artworkId
        self.artworkURL = artworkURL
        self.artworkThumbnailURL = artworkThumbnailURL
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.submit = submit
        self.title = title
        self._csrf = csrf
        self.error = error
    }

    init(
        song: Song,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try song.requireID()
        let artworkId = song.$artwork.id
        let artworkURL: String?
        let artworkThumbnailURL: String?
        if let artwork = song.artwork {
            artworkURL = "\(baseURL)/gallery/data/\(artwork.key)"
            artworkThumbnailURL = "\(baseURL)/gallery/data/\(artwork.thumbnailKey)"
        } else {
            artworkURL = nil
            artworkThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(song.title)'",
            access: song.access,
            album: song.album ?? "",
            artist: song.artist,
            artworkId: artworkId,
            artworkURL: artworkURL,
            artworkThumbnailURL: artworkThumbnailURL,
            genre: song.genre ?? "",
            notes: notes.map { NoteViewModel(body: $0.body, access: $0.access) },
            releaseDate: "",
            resourceURLs: song.resourceURLs,
            submit: Form.Submit(
                action: "/songs/\(id)",
                label: "Save"
            ),
            title: song.title,
            csrf: csrf
        )
    }
}

extension Template where Model == SongEditorViewModel {
    static let songEditor = Template(name: "Catalogue/Songs/song-editor")
}

extension Page {
    static var createSong: Self {
        Page(template: .songEditor) { req in
            try await req.permissions.songs.create()
            let submit = Form.Submit(
                action: "/songs/new",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return SongEditorViewModel(pageTitle: "New song", submit: submit, csrf: csrf)
        }
    }
    
    static var editSong: Self {
        Page(template: .songEditor) { request in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Song ID is incorrect or missing.")
            }
            async let song = request.commands.songs.fetch(songID, for: .write)
            async let notes = request.commands.notes.query(id: songID, of: Song.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await SongEditorViewModel(
                song: song,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
    }
}
