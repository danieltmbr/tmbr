import Foundation
import TmbrCore
import WebAuth
import WebCore

extension AlbumResponse {

    init(
        album: Album,
        notes: [Note],
        trackPreviews: [Preview] = [],
        baseURL: String,
        platform: Platform<AlbumMetadata> = .album
    ) throws {
        self.init(
            id: album.id!,
            access: album.access,
            artist: album.artist,
            artwork: album.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: album.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: album.owner),
            preview: PreviewResponse(preview: album.preview, baseURL: baseURL),
            post: try album.post.map { try PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: album.releaseDate,
            resources: album.resourceURLs.compactMap(platform.hyperlink),
            title: album.title,
            tracks: trackPreviews.enumerated().compactMap { index, preview in
                TrackItem(preview: preview, position: index + 1)
            }
        )
    }
}
