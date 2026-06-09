import TmbrCore
import Vapor
import Core

extension PlaylistResponse {

    init(
        playlist: Playlist,
        notes: [Note],
        trackPreviews: [Preview] = [],
        baseURL: String,
        platform: Platform<PlaylistMetadata> = .playlist
    ) {
        self.init(
            id: playlist.id!,
            access: playlist.access,
            artwork: playlist.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            description: playlist.description,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: playlist.owner),
            preview: PreviewResponse(preview: playlist.preview, baseURL: baseURL),
            post: playlist.post.map { PostResponse(post: $0, baseURL: baseURL) },
            resources: playlist.resourceURLs.compactMap(platform.hyperlink),
            title: playlist.title,
            tracks: trackPreviews.enumerated().compactMap { index, preview in
                TrackItem(preview: preview, position: index + 1)
            }
        )
    }
}
