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

    private let metadataEndpoint: String?

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
        metadataEndpoint: String?,
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
        self.metadataEndpoint = metadataEndpoint
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
        let resources = playlist.resourceURLs.compactMap(platform.hyperlink)
        let platformURL: URL? = allowsNewNote
            ? playlist.resourceURLs.compactMap { URL(string: $0) }.first(where: { platform.name(for: $0) != nil })
            : nil
        let syncEndpoint: String? = platformURL != nil ? "/playlists/\(playlistID)/sync-tracks" : nil
        let metadataEndpoint: String? = platformURL.map { url in
            let encoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? url.absoluteString
            return "/playlists/metadata?url=\(encoded)"
        }
        self.init(
            id: playlistID,
            artwork: playlist.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            allowsNewNote: allowsNewNote,
            createdAt: playlist.createdAt.map { $0.formatted(.releaseDate) },
            description: playlist.description,
            metadataEndpoint: metadataEndpoint,
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
            // Only promoted songs can have notes; skip the DB query for unpromoted tracks
            let promotedPreviewIDs = resolvedEntries.compactMap { entry -> PreviewID? in
                guard entry.preview.parentID != nil else { return nil }
                return entry.preview.id
            }
            let notesByPreviewID = try await request.commands.notes.fetchNotesByAttachments(promotedPreviewIDs)
            let tracks = resolvedEntries.map { entry -> TrackViewModel in
                let notes = entry.preview.parentID != nil
                    ? (entry.preview.id.flatMap { notesByPreviewID[$0] } ?? []).compactMap { try? NoteViewModel(note: $0) }
                    : []
                return TrackViewModel(entry: entry, notes: notes)
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
