import Foundation
import TmbrCore
import WebAuth
import WebCore

extension MovieResponse {

    init(
        movie: Movie,
        baseURL: String,
        notes: [Note],
        platform: Platform<MovieMetadata> = .movie
    ) {
        self.init(
            id: movie.id!,
            access: movie.access,
            cover: movie.cover.map { ImageResponse(image: $0, baseURL: baseURL) },
            director: movie.director,
            genre: movie.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: movie.owner),
            preview: PreviewResponse(preview: movie.preview, baseURL: baseURL),
            post: movie.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: movie.releaseDate,
            resources: movie.resourceURLs.compactMap(platform.hyperlink),
            title: movie.title
        )
    }
}
