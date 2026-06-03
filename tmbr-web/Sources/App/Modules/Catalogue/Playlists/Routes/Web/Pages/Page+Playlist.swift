import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct PlaylistViewModel: Encodable, Sendable {

    private let id: PlaylistID

    private let artwork: ImageViewModel?

    private let allowsNewNote: Bool

    private let description: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    private let tracks: [TrackViewModel]

    init(
        id: PlaylistID,
        artwork: ImageViewModel?,
        allowsNewNote: Bool,
        description: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String,
        tracks: [TrackViewModel] = []
    ) {
        self.id = id
        self.artwork = artwork
        self.allowsNewNote = allowsNewNote
        self.description = description
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.post = post
        self.resources = resources
        self.title = title
        self.tracks = tracks
    }

    init(
        playlist: Playlist,
        notes: [Note],
        tracks: [TrackViewModel],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<PlaylistMetadata> = .playlist
    ) throws {
        let playlistID = try playlist.requireID()
        self.init(
            id: playlistID,
            artwork: playlist.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            allowsNewNote: allowsNewNote,
            description: playlist.description,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/playlists/\(playlistID)/notes",
            post: try playlist.post.map(PostItemViewModel.init),
            resources: playlist.resourceURLs.compactMap(platform.hyperlink),
            title: playlist.title,
            tracks: tracks
        )
    }
}

extension Template where Model == PlaylistViewModel {
    static let playlist = Template(name: "Catalogue/Playlists/playlist")
}

extension Page {
    static var playlist: Self {
        Page(template: .playlist) { request in
            guard let playlistID = request.parameters.get("playlistID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            async let playlist = request.commands.playlists.fetch(playlistID, for: .read)
            async let notes = request.commands.notes.query(id: playlistID, of: Playlist.previewType, languages: request.languagePreference)
            async let entries = request.commands.previews.listContainerEntries(
                ContainerEntriesInput(containerType: "playlist", containerID: playlistID)
            )
            let resolvedPlaylist = try await playlist
            let allowsNewNote = (try? await request.permissions.playlists.edit.grant(resolvedPlaylist)) != nil
            let tracks = try await entries.map(TrackViewModel.init)
            return try PlaylistViewModel(
                playlist: resolvedPlaylist,
                notes: await notes,
                tracks: tracks,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
