import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct PlaylistEditorViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let id: String?
        let body: String
        let access: Access
    }

    private let artworkAspect: String = ""

    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let artworkId: Int?

    private let artworkSourceURL: String?

    private let artworkThumbnailURL: String?

    private let description: String

    private let notes: [NoteViewModel]

    private let resourceURLs: [String]

    private let submit: Form.Submit

    private let title: String

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String? = nil,
        access: Access = .private,
        artworkId: Int? = nil,
        artworkSourceURL: String? = nil,
        artworkThumbnailURL: String? = nil,
        description: String = "",
        notes: [NoteViewModel] = [],
        resourceURLs: [String] = [],
        submit: Form.Submit,
        title: String = "",
        csrf: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.access = access
        self.artworkId = artworkId
        self.artworkSourceURL = artworkSourceURL
        self.artworkThumbnailURL = artworkThumbnailURL
        self.description = description
        self.notes = notes
        self.resourceURLs = resourceURLs
        self.submit = submit
        self.title = title
        self._csrf = csrf
        self.error = error
    }

    init(
        playlist: Playlist,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try playlist.requireID()
        let artworkId = playlist.$artwork.id
        let artworkThumbnailURL: String?
        if let artwork = playlist.artwork {
            artworkThumbnailURL = "\(baseURL)/gallery/data/\(artwork.thumbnailKey)"
        } else {
            artworkThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(playlist.title)'",
            access: playlist.access,
            artworkId: artworkId,
            artworkSourceURL: nil,
            artworkThumbnailURL: artworkThumbnailURL,
            description: playlist.description ?? "",
            notes: notes.map { NoteViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access) },
            resourceURLs: playlist.resourceURLs,
            submit: Form.Submit(
                action: "/playlists/\(id)",
                label: "Save"
            ),
            title: playlist.title,
            csrf: csrf
        )
    }
}

extension Template where Model == PlaylistEditorViewModel {
    static let playlistEditor = Template(name: "Catalogue/editor")
}

extension Page {
    static var createPlaylist: Self {
        Page(template: .playlistEditor) { req in
            try await req.permissions.playlists.create()
            let submit = Form.Submit(
                action: "/playlists/new",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return PlaylistEditorViewModel(pageTitle: "New playlist", submit: submit, csrf: csrf)
        }
    }

    static var editPlaylist: Self {
        Page(template: .playlistEditor) { request in
            guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Playlist ID is incorrect or missing.")
            }
            async let playlist = request.commands.playlists.fetch(playlistID, for: .write)
            async let notes = request.commands.notes.query(id: playlistID, of: Playlist.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await PlaylistEditorViewModel(
                playlist: playlist,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
    }
}
