import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct AlbumEditorViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let id: String?
        let body: String
        let access: Access
    }

    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let artist: String

    private let artworkId: Int?

    private let artworkSourceURL: String?

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
        artist: String = "",
        artworkId: Int? = nil,
        artworkSourceURL: String? = nil,
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
        self.artist = artist
        self.artworkId = artworkId
        self.artworkSourceURL = artworkSourceURL
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
        album: Album,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try album.requireID()
        let artworkId = album.$artwork.id
        let artworkThumbnailURL: String?
        if let artwork = album.artwork {
            artworkThumbnailURL = "\(baseURL)/gallery/data/\(artwork.thumbnailKey)"
        } else {
            artworkThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(album.title)'",
            access: album.access,
            artist: album.artist,
            artworkId: artworkId,
            artworkSourceURL: nil,
            artworkThumbnailURL: artworkThumbnailURL,
            genre: album.genre ?? "",
            notes: notes.map { NoteViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access) },
            releaseDate: album.releaseDate?.formatted(.releaseDate) ?? "",
            resourceURLs: album.resourceURLs,
            submit: Form.Submit(
                action: "/albums/\(id)",
                label: "Save"
            ),
            title: album.title,
            csrf: csrf
        )
    }
}

extension Template where Model == AlbumEditorViewModel {
    static let albumEditor = Template(name: "Catalogue/Albums/album-editor")
}

extension Page {
    static var createAlbum: Self {
        Page(template: .albumEditor) { req in
            try await req.permissions.albums.create()
            let submit = Form.Submit(
                action: "/albums/new",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return AlbumEditorViewModel(pageTitle: "New album", submit: submit, csrf: csrf)
        }
    }

    static var editAlbum: Self {
        Page(template: .albumEditor) { request in
            guard let albumID = request.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Album ID is incorrect or missing.")
            }
            async let album = request.commands.albums.fetch(albumID, for: .write)
            async let notes = request.commands.notes.query(id: albumID, of: Album.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await AlbumEditorViewModel(
                album: album,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
    }
}
