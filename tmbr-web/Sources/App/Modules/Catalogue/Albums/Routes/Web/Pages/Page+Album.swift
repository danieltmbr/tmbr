import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

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

    private let tracks: [TrackViewModel]

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
        title: String,
        tracks: [TrackViewModel] = []
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
        self.tracks = tracks
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
        title: String,
        tracks: [TrackViewModel] = []
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
            title: title,
            tracks: tracks
        )
    }

    init(
        album: Album,
        notes: [Note],
        tracks: [TrackViewModel],
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
            title: album.title,
            tracks: tracks
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
            async let albumNotes = request.commands.notes.query(id: albumID, of: Album.previewType, languages: request.languagePreference)
            async let trackPreviews = request.commands.previews.listContainerPreviews("album", albumID)
            let resolvedAlbum = try await album
            let allowsNewNote = (try? await request.permissions.albums.edit.grant(resolvedAlbum)) != nil
            let resolvedTrackPreviews = try await trackPreviews
            let trackNotesByID = try await request.commands.notes.grouped(resolvedTrackPreviews.compactMap(\.id))
            let tracks = resolvedTrackPreviews.enumerated().compactMap { index, preview -> TrackViewModel? in
                guard let id = preview.id else { return nil }
                return TrackViewModel(
                    preview: preview,
                    position: index + 1,
                    notes: (trackNotesByID[id] ?? []).compactMap { try? NoteViewModel(note: $0) }
                )
            }
            return try AlbumViewModel(
                album: resolvedAlbum,
                notes: await albumNotes,
                tracks: tracks,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
