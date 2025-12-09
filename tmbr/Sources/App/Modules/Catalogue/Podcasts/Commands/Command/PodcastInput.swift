import Foundation
import Vapor
import AuthKit

struct PodcastInput {
    
    fileprivate let access: Access
        
    fileprivate let artwork: ImageID?
    
    fileprivate let episodeNumber: Int?
    
    fileprivate let episodeTitle: String
    
    fileprivate let genre: String?
        
    fileprivate let releaseDate: Date?
    
    fileprivate let resourceURLs: [String]
    
    fileprivate let seasonNumber: Int?
    
    fileprivate let title: String

    func validate() throws {
        guard !title.trimmed.isEmpty,
              !episodeTitle.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "The podcast title or episode title is missing")
        }
    }
    
    init(
        access: Access,
        artwork: ImageID?,
        episodeNumber: Int?,
        episodeTitle: String,
        genre: String?,
        releaseDate: Date?,
        resourceURLs: [String],
        seasonNumber: Int?,
        title: String
    ) {
        self.access = access
        self.artwork = artwork
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.seasonNumber = seasonNumber
        self.title = title
    }
    
    init(payload: PodcastPayload) {
        self.init(
            access: payload.access,
            artwork: payload.artwork,
            episodeNumber: payload.episodeNumber,
            episodeTitle: payload.episodeTitle,
            genre: payload.genre,
            releaseDate: payload.releaseDate,
            resourceURLs: payload.resourceURLs,
            seasonNumber: payload.seasonNumber,
            title: payload.title
        )
    }
}

struct PodcastConfiguration {
    
    static let `default` = PodcastConfiguration { podcast, input in
        podcast.access = input.access
        podcast.$artwork.id = input.artwork
        podcast.episodeNumber = input.episodeNumber
        podcast.episodeTitle = input.episodeTitle
        podcast.genre = input.genre
        podcast.releaseDate = input.releaseDate
        podcast.resourceURLs = input.resourceURLs
        podcast.seasonNumber = input.seasonNumber
        podcast.title = input.title
    }
    
    private let configure: @Sendable (Podcast, PodcastInput) -> Void
    
    init(configure: @Sendable @escaping (Podcast, PodcastInput) -> Void) {
        self.configure = configure
    }
    
    func callAsFunction(_ podcast: Podcast, with input: PodcastInput) {
        configure(podcast, input)
    }
}
