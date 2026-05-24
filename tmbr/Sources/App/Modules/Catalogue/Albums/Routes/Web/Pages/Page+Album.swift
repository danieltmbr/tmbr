import Vapor
import Foundation
import AuthKit
import Core

struct AlbumViewModel: Encodable, Sendable {

    private let id: AlbumID

    private let artist: String

    private let artwork: ImageViewModel?

    private let allowsNewNote: Bool

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: AlbumID,
        artist: String,
        artwork: ImageViewModel?,
        allowsNewNote: Bool,
        info: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.artist = artist
        self.artwork = artwork
        self.allowsNewNote = allowsNewNote
        self.info = info
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.post = post
        self.resources = resources
        self.title = title
    }

    init(
        id: AlbumID,
        artist: String,
        artwork: ImageViewModel?,
        allowsNewNote: Bool,
        genre: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        title: String
    ) {
        self.init(
            id: id,
            artist: artist,
            artwork: artwork,
            allowsNewNote: allowsNewNote,
            info: {
                let parts = [genre, releaseDate].compactMap(\.self).filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: ", ")
            }(),
            notes: notes,
            notesEndpoint: notesEndpoint,
            post: post,
            resources: resources,
            title: title
        )
    }

    init(
        album: Album,
        notes: [Note],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<AlbumMetadata> = .album
    ) throws {
        let albumID = try album.requireID()
        self.init(
            id: albumID,
            artist: album.artist,
            artwork: album.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            allowsNewNote: allowsNewNote,
            genre: album.genre,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/albums/\(albumID)/notes",
            post: try album.post.map(PostItemViewModel.init),
            releaseDate: album.releaseDate?.formatted(.releaseDate),
            resources: album.resourceURLs.compactMap(platform.hyperlink),
            title: album.title
        )
    }
}

extension Template where Model == AlbumViewModel {
    static let album = Template(name: "Catalogue/Albums/album")
}

extension Page {
    static var album: Self {
        Page(template: .album) { request in
            guard let albumID = request.parameters.get("albumID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            async let album = request.commands.albums.fetch(albumID, for: .read)
            async let notes = request.commands.notes.query(id: albumID, of: Album.previewType)
            let resolvedAlbum = try await album
            let allowsNewNote = (try? await request.permissions.albums.edit.grant(resolvedAlbum)) != nil
            return try AlbumViewModel(
                album: resolvedAlbum,
                notes: await notes,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
