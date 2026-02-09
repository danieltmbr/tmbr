import Vapor
import Foundation
import AuthKit
import Core

struct PodcastViewModel: Encodable, Sendable {
    
    private let id: PodcastID
    
    private let artwork: ImageViewModel?
    
    private let episodeNumber: Int?
    
    private let episodeTitle: String
    
    private let genre: String?
    
    private let notes: [NoteViewModel]
    
    private let post: PostItemViewModel?
    
    private let releaseDate: String?
    
    private let resources: [Hyperlink]
    
    private let seasonNumber: Int?
    
    private let title: String
    
    init(
        id: PodcastID,
        artwork: ImageViewModel?,
        episodeNumber: Int?,
        episodeTitle: String,
        genre: String?,
        notes: [NoteViewModel],
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        seasonNumber: Int?,
        title: String
    ) {
        self.id = id
        self.artwork = artwork
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.notes = notes
        self.post = post
        self.releaseDate = releaseDate
        self.resources = resources
        self.seasonNumber = seasonNumber
        self.title = title
    }
    
    init(
        podcast: Podcast,
        notes: [Note],
        baseURL: String,
        platform: Platform<Podcast> = .all
    ) throws {
        self.init(
            id: try podcast.requireID(),
            artwork: podcast.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            episodeNumber: podcast.episodeNumber,
            episodeTitle: podcast.episodeTitle,
            genre: podcast.genre,
            notes: try notes.map(NoteViewModel.init),
            post: try podcast.post.map(PostItemViewModel.init),
            releaseDate: podcast.releaseDate?.formatted(.releaseDate),
            resources: podcast.resourceURLs.compactMap(platform.hyperlink),
            seasonNumber: podcast.seasonNumber,
            title: podcast.title
        )
    }
}

extension Template where Model == PodcastViewModel {
    static let podcast = Template(name: "Catalogue/Podcasts/podcast")
}

extension Page {
    static var podcast: Self {
        Page(template: .podcast) { request in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            return try await request.commands.transaction { commands in
                async let podcast = commands.podcasts.fetch(podcastID, for: .read)
                async let notes = commands.notes.query(id: podcastID, of: Podcast.previewType)
                
                return try PodcastViewModel(
                    podcast: await podcast,
                    notes: await notes,
                    baseURL: request.baseURL
                )
            }
        }
    }
}
