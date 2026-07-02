import Foundation
import TmbrCore
import WebAuth
import WebCore

extension PodcastResponse {

    init(
        podcast: Podcast,
        baseURL: String,
        notes: [Note],
        platform: Platform<PodcastMetadata> = .podcast
    ) throws {
        self.init(
            id: podcast.id!,
            access: podcast.access,
            artwork: podcast.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            episodeNumber: podcast.episodeNumber,
            episodeTitle: podcast.episodeTitle,
            genre: podcast.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: podcast.owner),
            preview: PreviewResponse(preview: podcast.preview, baseURL: baseURL),
            post: try podcast.post.map { try PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: podcast.releaseDate,
            resources: podcast.resourceURLs.compactMap(platform.hyperlink),
            seasonNumber: podcast.seasonNumber,
            title: podcast.title
        )
    }
}
