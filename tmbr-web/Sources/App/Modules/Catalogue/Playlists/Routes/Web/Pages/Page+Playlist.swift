import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct PlaylistViewModel: Encodable, Sendable {

    private let id: PlaylistID

    private let artwork: ImageViewModel?

    private let allowsNewNote: Bool

    private let createdAt: String?

    private let description: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let syncEndpoint: String?

    private let title: String

    let _csrf: String?

    private let tracks: [TrackViewModel]

    init(
        id: PlaylistID,
        artwork: ImageViewModel?,
        allowsNewNote: Bool,
        createdAt: String?,
        description: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        syncEndpoint: String?,
        title: String,
        tracks: [TrackViewModel] = [],
        csrf: String? = nil
    ) {
        self.id = id
        self.artwork = artwork
        self.allowsNewNote = allowsNewNote
        self.createdAt = createdAt
        self.description = description
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.post = post
        self.resources = resources
        self.syncEndpoint = syncEndpoint
        self.title = title
        self.tracks = tracks
        self._csrf = csrf
    }

    init(
        playlist: Playlist,
        notes: [Note],
        tracks: [TrackViewModel],
        baseURL: String,
        allowsNewNote: Bool,
        csrf: String? = nil,
        platform: Platform<PlaylistMetadata> = .playlist
    ) throws {
        let playlistID = try playlist.requireID()
        let resolvedPlatform = platform
        let resources = playlist.resourceURLs.compactMap(resolvedPlatform.hyperlink)
        // Expose sync endpoint to the detail page only for owners when an Apple Music URL is present
        let hasAppleMusicURL = resources.contains(where: { $0.urlString.contains("music.apple.com") })
        let syncEndpoint = allowsNewNote && hasAppleMusicURL ? "/playlists/\(playlistID)/sync-tracks" : nil
        self.init(
            id: playlistID,
            artwork: playlist.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            allowsNewNote: allowsNewNote,
            createdAt: playlist.createdAt.map { $0.formatted(.releaseDate) },
            description: playlist.description,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/playlists/\(playlistID)/notes",
            post: try playlist.post.map(PostItemViewModel.init),
            resources: resources,
            syncEndpoint: syncEndpoint,
            title: playlist.title,
            tracks: tracks,
            csrf: csrf
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
            let resolvedEntries = try await entries
            let trackPreviewIDs = resolvedEntries.compactMap { $0.preview.id }
            let notesByPreviewID = try await request.commands.notes.fetchTrackNotes(trackPreviewIDs)
            let tracks = resolvedEntries.map { entry -> TrackViewModel in
                let entryNotes = entry.preview.id.flatMap { notesByPreviewID[$0] } ?? []
                return TrackViewModel(entry: entry, notes: entryNotes.compactMap { try? NoteViewModel(note: $0) })
            }
            let csrf: String?
            if allowsNewNote {
                let token = UUID().uuidString
                request.session.data["csrf.sync"] = token
                csrf = token
            } else {
                csrf = nil
            }
            return try PlaylistViewModel(
                playlist: resolvedPlaylist,
                notes: await notes,
                tracks: tracks,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote,
                csrf: csrf
            )
        }
    }
}
