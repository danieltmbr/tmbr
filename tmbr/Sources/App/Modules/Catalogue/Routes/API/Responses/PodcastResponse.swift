import Vapor
import Foundation
import AuthKit

struct PodcastResponse: Encodable, Sendable {
    
    private let id: PodcastID
    
    private let access: Access
    
    private let artwork: ImageResponse?
    
    private let episodeNumber: Int?
    
    private let episodeTitle: String
    
    private let genre: String?
        
    private let notes: [NoteResponse]
    
    private let owner: UserResponse
        
    private let preview: PreviewResponse
    
    private let post: PostResponse?
    
    private let releaseDate: Date?
    
    private let resources: [Resource]

    private let seasonNumber: Int?
    
    private let title: String
    
    init(
        id: PodcastID,
        access: Access,
        artwork: ImageResponse?,
        episodeNumber: Int?,
        episodeTitle: String,
        genre: String?,
        notes: [NoteResponse],
        owner: UserResponse,
        preview: PreviewResponse,
        post: PostResponse?,
        releaseDate: Date?,
        resources: [Resource],
        seasonNumber: Int?,
        title: String
    ) {
        self.id = id
        self.access = access
        self.artwork = artwork
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.notes = notes
        self.owner = owner
        self.preview = preview
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.seasonNumber = seasonNumber
        self.title = title
    }
    
    init(
        podcast: Podcast,
        baseURL: String,
        platform: Platform<Podcast> = .all
    ) {
        self.init(
            id: podcast.id!,
            access: podcast.access,
            artwork: podcast.artwork.map { ImageResponse(image: $0, baseURL: baseURL) },
            episodeNumber: podcast.episodeNumber,
            episodeTitle: podcast.episodeTitle,
            genre: podcast.genre,
            notes: podcast.notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: podcast.owner),
            preview: PreviewResponse(preview: podcast.preview, baseURL: baseURL),
            post: podcast.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: podcast.releaseDate,
            resources: podcast.resourceURLs.compactMap(platform.resource),
            seasonNumber: podcast.seasonNumber,
            title: podcast.title
        )
    }
}
