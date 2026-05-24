import Core
import Foundation
import Vapor
import AuthKit
import TmbrCore

private struct AlbumPreviewPayload: Content {
    let title: String
    let artist: String
    let genre: String?
    let releaseDate: String?
    let artworkURL: String?
    let resourceURLs: String?
    let notes: String
}

extension Page {
    static var albumPreview: Self {
        Page(template: .album) { req in
            try await req.permissions.albums.create.grant()
            let payload = try req.content.decode(AlbumPreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<AlbumMetadata>.album
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            return AlbumViewModel(
                id: 0,
                artist: payload.artist,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                allowsNewNote: false,
                genre: payload.genre,
                notes: notes,
                notesEndpoint: "",
                post: nil,
                releaseDate: payload.releaseDate,
                resources: resources,
                title: "Preview: \(payload.title)"
            )
        }
    }
}
