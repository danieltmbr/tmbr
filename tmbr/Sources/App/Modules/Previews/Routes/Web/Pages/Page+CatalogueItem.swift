import Vapor
import Foundation
import AuthKit
import Core

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

    init(preview: Preview, baseURL: String) {
        title = preview.primaryInfo
        subtitle = preview.secondaryInfo
        artwork = preview.image.flatMap { ImageViewModel(image: $0, baseURL: baseURL) }
        info = nil
        notes = []
        notesEndpoint = "/catalogue/item/\(preview.id!)/notes"
        resources = preview.externalLinks.compactMap { urlString in
            guard let url = URL(string: urlString) else { return nil }
            return Hyperlink(label: url.host ?? urlString, url: url)
        }
        allowsNewNote = false
        post = nil
    }
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
            let preview = try await request.commands.previews.fetch(previewID, for: .read)
            return CatalogueItemViewModel(preview: preview, baseURL: request.baseURL)
        }
    }
}
