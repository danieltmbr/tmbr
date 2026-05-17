import Core
import Foundation
import Vapor
import AuthKit

private struct SongPreviewPayload: Content {
    let title: String
    let artist: String
    let album: String?
    let genre: String?
    let releaseDate: String?
    let artworkURL: String?
    let resourceURLs: String?
    let notes: String
}

extension Page {
    static var songPreview: Self {
        Page(template: .song) { req in
            try await req.permissions.songs.create.grant()
            let payload = try req.content.decode(SongPreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<SongMetadata>.song
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            return SongViewModel(
                id: 0,
                album: payload.album,
                artist: payload.artist,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                allowsNewNote: false,
                genre: payload.genre,
                notes: notes,
                post: nil,
                releaseDate: payload.releaseDate,
                resources: resources,
                title: "Preview: \(payload.title)"
            )
        }
    }
}
