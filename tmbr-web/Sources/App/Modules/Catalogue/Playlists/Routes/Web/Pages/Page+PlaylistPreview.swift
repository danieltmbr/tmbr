import Core
import Foundation
import Vapor
import AuthKit
import TmbrCore

private struct PlaylistPreviewPayload: Content {
    let title: String
    let description: String?
    let artworkURL: String?
    let resourceURLs: String?
    let notes: String
    let tracklistJSON: String?

    enum CodingKeys: String, CodingKey {
        case title, description, artworkURL, resourceURLs, notes
        case tracklistJSON = "tracklist-json"
    }
}

extension Page {
    static var playlistPreview: Self {
        Page(template: .playlist) { req in
            try await req.permissions.playlists.create.grant()
            let payload = try req.content.decode(PlaylistPreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<PlaylistMetadata>.playlist
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            let tracks: [TrackViewModel] = payload.tracklistJSON
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONDecoder().decode([TrackMetadata].self, from: $0) }
                .map { $0.enumerated().map { TrackViewModel(name: $1.name, position: $0 + 1, url: $1.url) } }
                ?? []
            return PlaylistViewModel(
                id: 0,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                allowsNewNote: false,
                platformCreatedAt: nil,
                description: payload.description,
                metadataEndpoint: nil,
                notes: notes,
                notesEndpoint: "",
                post: nil,
                resources: resources,
                syncEndpoint: nil,
                title: "Preview: \(payload.title)",
                tracks: tracks
            )
        }
    }
}
