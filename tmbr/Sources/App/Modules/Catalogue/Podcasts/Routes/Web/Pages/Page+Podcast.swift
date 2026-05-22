import Vapor
import Foundation
import AuthKit
import Core

struct PodcastViewModel: Encodable, Sendable {

    private let id: PodcastID

    private let allowsNewNote: Bool

    private let artwork: ImageViewModel?

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let subtitle: String?

    private let post: PostItemViewModel?

    private let resources: [Hyperlink]

    private let title: String

    init(
        id: PodcastID,
        allowsNewNote: Bool,
        artwork: ImageViewModel?,
        info: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        episodeTitle: String,
        post: PostItemViewModel?,
        resources: [Hyperlink],
        title: String
    ) {
        self.id = id
        self.allowsNewNote = allowsNewNote
        self.artwork = artwork
        self.info = info
        self.notes = notes
        self.notesEndpoint = notesEndpoint
        self.title = episodeTitle
        self.subtitle = "from \(title)"
        self.post = post
        self.resources = resources
    }

    init(
        id: PodcastID,
        allowsNewNote: Bool,
        artwork: ImageViewModel?,
        episodeNumber: Int?,
        genre: String?,
        notes: [NoteViewModel],
        notesEndpoint: String,
        episodeTitle: String,
        post: PostItemViewModel?,
        releaseDate: String?,
        resources: [Hyperlink],
        seasonNumber: Int?,
        title: String
    ) {
        let seasonEpisode: String? = {
            if let s = seasonNumber, let e = episodeNumber {
                return "S\(s):E\(e)"
            } else if let e = episodeNumber {
                return "E\(e)"
            }
            return nil
        }()
        let parts = [seasonEpisode, genre, releaseDate].compactMap(\.self).filter { !$0.isEmpty }
        self.init(
            id: id,
            allowsNewNote: allowsNewNote,
            artwork: artwork,
            info: parts.isEmpty ? nil : parts.joined(separator: ", "),
            notes: notes,
            notesEndpoint: notesEndpoint,
            episodeTitle: episodeTitle,
            post: post,
            resources: resources,
            title: title
        )
    }

    init(
        podcast: Podcast,
        notes: [Note],
        baseURL: String,
        allowsNewNote: Bool,
        platform: Platform<PodcastMetadata> = .podcast
    ) throws {
        let podcastID = try podcast.requireID()
        self.init(
            id: podcastID,
            allowsNewNote: allowsNewNote,
            artwork: podcast.artwork.flatMap {
                ImageViewModel(image: $0, baseURL: baseURL)
            },
            episodeNumber: podcast.episodeNumber,
            genre: podcast.genre,
            notes: try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) },
            notesEndpoint: "/podcasts/\(podcastID)/notes",
            episodeTitle: podcast.episodeTitle,
            post: try podcast.post.map(PostItemViewModel.init),
            releaseDate: podcast.releaseDate?.formatted(.releaseDate),
            resources: podcast.resourceURLs.compactMap(platform.hyperlink),
            seasonNumber: podcast.seasonNumber,
            title: podcast.title
        )
    }
}

extension Template where Model == PodcastViewModel {
    static let podcast = Template(name: "Catalogue/details")
}

extension Page {
    static var podcast: Self {
        Page(template: .podcast) { request in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest)
            }
            async let podcastTask = request.commands.podcasts.fetch(podcastID, for: .read)
            async let notesTask = request.commands.notes.query(id: podcastID, of: Podcast.previewType)
            let resolvedPodcast = try await podcastTask
            let allowsNewNote = (try? await request.permissions.podcasts.edit.grant(resolvedPodcast)) != nil
            return try PodcastViewModel(
                podcast: resolvedPodcast,
                notes: await notesTask,
                baseURL: request.baseURL,
                allowsNewNote: allowsNewNote
            )
        }
    }
}
