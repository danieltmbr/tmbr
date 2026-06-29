import WebCore
import Foundation
import Vapor
import WebAuth
import TmbrCore

private struct AlbumPreviewPayload: Content {
    let title: String
    let artist: String
    let genre: String?
    let releaseDate: String?
    let artworkURL: String?
    let resourceURLs: String?
    let notes: String
    let tracklistJSON: String?

    enum CodingKeys: String, CodingKey {
        case title, artist, genre, releaseDate, artworkURL, resourceURLs, notes
        case tracklistJSON = "tracklist-json"
    }
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
            let tracks: [TrackViewModel] = payload.tracklistJSON
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try? JSONDecoder().decode([TrackMetadata].self, from: $0) }
                .map { $0.enumerated().map { TrackViewModel(name: $1.name, position: $0 + 1, url: $1.url) } }
                ?? []
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
                title: "Preview: \(payload.title)",
                tracks: tracks
            )
        }
    }
}
