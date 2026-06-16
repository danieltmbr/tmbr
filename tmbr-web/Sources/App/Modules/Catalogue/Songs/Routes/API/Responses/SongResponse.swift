import Foundation
import CoreTmbr
import CoreAuth
import CoreWeb

extension SongResponse {

    init(
        song: Song,
        notes: [Note],
        baseURL: String,
        platform: Platform<SongMetadata> = .song
    ) {
        self.init(
            id: song.id!,
            access: song.access,
            album: song.album,
            artist: song.artist,
            artwork: song.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: song.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: song.owner),
            preview: PreviewResponse(preview: song.preview, baseURL: baseURL),
            post: song.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: song.releaseDate,
            resources: song.resourceURLs.compactMap(platform.hyperlink),
            title: song.title
        )
    }
}
