import Vapor
import Foundation
import AuthKit
import Core

struct SongViewModel: Encodable, Sendable {

    private let id: SongID

    private let subtitle: String

    private let artwork: ImageViewModel?

    private let allowsNewNote: Bool

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: SongID,
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
        self.subtitle = "by \(artist)"
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
        id: SongID,
        album: String?,
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
                let parts = [album, genre, releaseDate].compactMap(\.self).filter { !$0.isEmpty }
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
        song: Song,
        notes: [Note],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<SongMetadata> = .song
    ) throws {
        let songID = try song.requireID()
        self.init(
            id: songID,
            album: song.album,
            artist: song.artist,
            artwork: song.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            allowsNewNote: allowsNewNote,
            genre: song.genre,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/songs/\(songID)/notes",
            post: try song.post.map(PostItemViewModel.init),
            releaseDate: song.releaseDate?.formatted(.releaseDate),
            resources: song.resourceURLs.compactMap(platform.hyperlink),
            title: song.title
        )
    }
}

extension Template where Model == SongViewModel {
    static let song = Template(name: "Catalogue/Songs/song")
}

extension Page {
    static var song: Self {
        Page(template: .song) { request in
            guard let songID = request.parameters.get("songID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            async let song = request.commands.songs.fetch(songID, for: .read)
            async let notes = request.commands.notes.query(id: songID, of: Song.previewType)
            let resolvedSong = try await song
            let allowsNewNote = (try? await request.permissions.songs.edit.grant(resolvedSong)) != nil
            return try SongViewModel(
                song: resolvedSong,
                notes: await notes,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
