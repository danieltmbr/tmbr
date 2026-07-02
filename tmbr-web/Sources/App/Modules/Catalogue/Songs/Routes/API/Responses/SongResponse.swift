import Foundation
import TmbrCore
import WebAuth
import WebCore

extension SongResponse {

    init(
        song: Song,
        notes: [Note],
        baseURL: String,
        platform: Platform<SongMetadata> = .song
    ) throws {
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
            post: try song.post.map { try PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: song.releaseDate,
            resources: song.resourceURLs.compactMap(platform.hyperlink),
            title: song.title
        )
    }
}
