import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct CatalogueItemViewModel: Encodable, Sendable {

    private let title: String

    private let subtitle: String?

    private let artwork: ImageViewModel?

    private let info: String?

    private let notes: [NoteViewModel]

    private let notesEndpoint: String

    private let resources: [Hyperlink]

    private let allowsNewNote: Bool

    private let post: PostItemViewModel?

    init(
        preview: Preview,
        notes: [Note],
        allowsNewNote: Bool,
        baseURL: String
    ) throws {
        title = preview.primaryInfo
        subtitle = preview.secondaryInfo
        artwork = preview.image.flatMap { ImageViewModel(image: $0, baseURL: baseURL) }
        info = nil
        self.notes = try notes.map { try NoteViewModel(note: $0, isEditable: allowsNewNote) }
        notesEndpoint = "/catalogue/item/\(preview.id!)/notes"
        resources = preview.externalLinks.compactMap { urlString in
            guard let url = URL(string: urlString) else { return nil }
            return Hyperlink(label: url.host ?? urlString, url: url)
        }
        self.allowsNewNote = allowsNewNote
        post = nil
    }

    init(previewing payload: CataloguePreviewPayload) {
        title = "Preview: \(payload.title)"
        subtitle = payload.subtitle
        artwork = payload.artworkURL.flatMap { url in
            url.isEmpty ? nil : ImageViewModel(previewURL: url)
        }
        info = nil
        let formatter = MarkdownFormatter.html
        notes = payload.notes.isEmpty ? [] : [
            NoteViewModel(
                id: UUID(),
                body: formatter.format(payload.notes),
                created: Date.now.formatted(.publishDate)
            )
        ]
        notesEndpoint = ""
        resources = payload.url.flatMap { urlString -> Hyperlink? in
            guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }
            return Hyperlink(label: url.host ?? urlString, url: url)
        }.map { [$0] } ?? []
        allowsNewNote = false
        post = nil
    }
}

struct CataloguePreviewPayload: Decodable, Sendable {
    let title: String
    let subtitle: String?
    let artworkURL: String?
    let url: String?
    let notes: String
}

extension Template where Model == CatalogueItemViewModel {
    static let catalogueItemPreview = Template(name: "Catalogue/item")
}

extension Template where Model == CatalogueItemViewModel {
    static let catalogueItem = Template(name: "Catalogue/details")
}

extension Page {
    static var catalogueItem: Self {
        Page(template: .catalogueItem) { request in
            guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
                throw Abort(.badRequest)
            }
            async let preview = request.commands.previews.fetch(previewID, for: .read)
            async let notes = request.commands.notes.fetchByAttachment(previewID)
            let resolvedPreview = try await preview
            let allowsNewNote = (try? await request.permissions.previews.edit.grant(resolvedPreview)) != nil
            return try CatalogueItemViewModel(
                preview: resolvedPreview,
                notes: try await notes,
                allowsNewNote: allowsNewNote,
                baseURL: request.baseURL
            )
        }
    }
}
