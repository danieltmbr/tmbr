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
            return PlaylistViewModel(
                id: 0,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                allowsNewNote: false,
                addedAt: nil,
                description: payload.description,
                metadataEndpoint: nil,
                notes: notes,
                notesEndpoint: "",
                post: nil,
                resources: resources,
                syncEndpoint: nil,
                title: "Preview: \(payload.title)"
            )
        }
    }
}
