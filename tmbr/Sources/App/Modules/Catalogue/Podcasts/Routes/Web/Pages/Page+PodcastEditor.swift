import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct PodcastEditorViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let id: String?
        let body: String
        let access: Access
    }

    private let artworkAspect: String = ""

    private let id: Int?

    private let pageTitle: String?

    private let access: Access

    private let artworkId: Int?

    private let artworkSourceURL: String?

    private let artworkThumbnailURL: String?

    private let episodeNumber: String

    private let episodeTitle: String

    private let genre: String

    private let notes: [NoteViewModel]

    private let releaseDate: String

    private let resourceURLs: [String]

    private let seasonNumber: String

    private let submit: Form.Submit

    private let title: String

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String? = nil,
        access: Access = .private,
        artworkId: Int? = nil,
        artworkSourceURL: String? = nil,
        artworkThumbnailURL: String? = nil,
        episodeNumber: String = "",
        episodeTitle: String = "",
        genre: String = "",
        notes: [NoteViewModel] = [],
        releaseDate: String = "",
        resourceURLs: [String] = [],
        seasonNumber: String = "",
        submit: Form.Submit,
        title: String = "",
        csrf: String? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.access = access
        self.artworkId = artworkId
        self.artworkSourceURL = artworkSourceURL
        self.artworkThumbnailURL = artworkThumbnailURL
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
        self.genre = genre
        self.notes = notes
        self.releaseDate = releaseDate
        self.resourceURLs = resourceURLs
        self.seasonNumber = seasonNumber
        self.submit = submit
        self.title = title
        self._csrf = csrf
        self.error = error
    }

    init(
        podcast: Podcast,
        notes: [Note],
        baseURL: String,
        csrf: String?
    ) throws {
        let id = try podcast.requireID()
        let artworkId = podcast.$artwork.id
        let artworkThumbnailURL: String?
        if let artwork = podcast.artwork {
            artworkThumbnailURL = "\(baseURL)/gallery/data/\(artwork.thumbnailKey)"
        } else {
            artworkThumbnailURL = nil
        }
        self.init(
            id: id,
            pageTitle: "Edit '\(podcast.episodeTitle)'",
            access: podcast.access,
            artworkId: artworkId,
            artworkSourceURL: nil,
            artworkThumbnailURL: artworkThumbnailURL,
            episodeNumber: podcast.episodeNumber.map(String.init) ?? "",
            episodeTitle: podcast.episodeTitle,
            genre: podcast.genre ?? "",
            notes: notes.map { NoteViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access) },
            releaseDate: podcast.releaseDate?.formatted(.releaseDate) ?? "",
            resourceURLs: podcast.resourceURLs,
            seasonNumber: podcast.seasonNumber.map(String.init) ?? "",
            submit: Form.Submit(action: "/podcasts/\(id)", label: "Save"),
            title: podcast.title,
            csrf: csrf
        )
    }
}

extension Template where Model == PodcastEditorViewModel {
    static let podcastEditor = Template(name: "Catalogue/Podcasts/podcast-editor")
}

extension Page {
    static var createPodcast: Self {
        Page(template: .podcastEditor) { req in
            try await req.permissions.podcasts.create()
            let submit = Form.Submit(action: "/podcasts/new", label: "Save")
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return PodcastEditorViewModel(pageTitle: "New podcast", submit: submit, csrf: csrf)
        }
    }

    static var editPodcast: Self {
        Page(template: .podcastEditor) { request in
            guard let podcastID = request.parameters.get("podcastID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Podcast ID is incorrect or missing.")
            }
            async let podcast = request.commands.podcasts.fetch(podcastID, for: .write)
            async let notes = request.commands.notes.query(id: podcastID, of: Podcast.previewType)
            let csrf = UUID().uuidString
            request.session.data["csrf.editor"] = csrf
            return try await PodcastEditorViewModel(
                podcast: podcast,
                notes: notes,
                baseURL: request.baseURL,
                csrf: csrf
            )
        }
    }
}

private struct PodcastPreviewPayload: Content {
    let episodeTitle: String
    let title: String
    let genre: String?
    let releaseDate: String?
    let artworkURL: String?
    let resourceURLs: String?
    let notes: String
    let seasonNumber: Int?
    let episodeNumber: Int?
}

extension Page {
    static var podcastPreview: Self {
        Page(template: .podcast) { req in
            try await req.permissions.podcasts.create.grant()
            let payload = try req.content.decode(PodcastPreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let platform = Platform<PodcastMetadata>.podcast
            let resources = (payload.resourceURLs ?? "")
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .compactMap(platform.hyperlink)
            return PodcastViewModel(
                id: 0,
                allowsNewNote: false,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                episodeNumber: payload.episodeNumber,
                genre: payload.genre,
                notes: notes,
                notesEndpoint: "",
                episodeTitle: "Preview: \(payload.episodeTitle)",
                post: nil,
                releaseDate: payload.releaseDate,
                resources: resources,
                seasonNumber: payload.seasonNumber,
                title: payload.title
            )
        }
    }
}
