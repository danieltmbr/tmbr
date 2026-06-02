import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

struct CatalogueNewViewModel: Encodable, Sendable {

    struct NoteViewModel: Encodable, Sendable {
        let id: String?
        let body: String
        let access: Access
    }

    private let url: String?
    private let title: String
    private let subtitle: String?
    private let artworkURL: String?
    private let category: String
    private let access: String
    private let categories: [String]
    private let notes: [NoteViewModel]
    private let error: String?

    init(
        url: String? = nil,
        title: String = "",
        subtitle: String? = nil,
        artworkURL: String? = nil,
        category: String = "",
        access: Access = .public,
        categories: [String] = [],
        notes: [NoteViewModel] = [],
        error: String? = nil
    ) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.category = category
        self.access = access.rawValue
        self.categories = categories
        self.notes = notes
        self.error = error
    }
}

extension Template where Model == CatalogueNewViewModel {
    static let catalogueNew = Template(name: "Catalogue/catalogue-new")
}

extension Page {
    static var catalogueNew: Self {
        Page(template: .catalogueNew) { request in
            let user = try request.auth.require(User.self)
            let userID = try user.requireID()
            let categories = (try? await request.commands.previews.listShallowCategories(userID)) ?? []
            return CatalogueNewViewModel(categories: categories)
        }
    }
}

// MARK: - Preview

private struct CataloguePreviewPayload: Content {
    let title: String
    let subtitle: String?
    let artworkURL: String?
    let url: String?
    let notes: String
}

extension Template where Model == CatalogueItemViewModel {
    static let cataloguePreview = Template(name: "Previews/preview")
}

extension Page {
    static var cataloguePreview: Self {
        Page(template: .cataloguePreview) { request in
            try request.auth.require(User.self)
            let payload = try request.content.decode(CataloguePreviewPayload.self)
            let formatter = MarkdownFormatter.html
            let notes: [NoteViewModel] = payload.notes.isEmpty ? [] : [
                NoteViewModel(
                    id: UUID(),
                    body: formatter.format(payload.notes),
                    created: Date.now.formatted(.publishDate)
                )
            ]
            let resource: Hyperlink? = payload.url.flatMap { urlString in
                guard !urlString.isEmpty, let url = URL(string: urlString) else { return nil }
                return Hyperlink(label: url.host ?? urlString, url: url)
            }
            return CatalogueItemViewModel(
                title: "Preview: \(payload.title)",
                subtitle: payload.subtitle,
                artwork: payload.artworkURL.flatMap { url in
                    url.isEmpty ? nil : ImageViewModel(previewURL: url)
                },
                notes: notes,
                resources: resource.map { [$0] } ?? []
            )
        }
    }
}
