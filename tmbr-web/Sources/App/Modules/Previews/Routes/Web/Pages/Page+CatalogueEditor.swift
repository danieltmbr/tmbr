import Vapor
import Foundation
import WebAuth
import WebCore
import TmbrCore

struct CatalogueEditorViewModel: Encodable, Sendable {

    private let previewID: String?
    private let url: String?
    private let title: String
    private let subtitle: String?
    private let artworkURL: String?
    private let category: String
    private let access: String
    private let categories: [String]
    private let notes: [NoteEditorViewModel]
    private let error: String?

    init(
        previewID: UUID? = nil,
        url: String? = nil,
        title: String = "",
        subtitle: String? = nil,
        artworkURL: String? = nil,
        category: String = "",
        access: Access = .public,
        categories: [String] = [],
        notes: [NoteEditorViewModel] = [],
        error: String? = nil
    ) {
        self.previewID = previewID.map { $0.uuidString }
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

extension Template where Model == CatalogueEditorViewModel {
    static let catalogueEditor = Template(name: "Catalogue/catalogue-editor")
}

extension Page {
    static var catalogueNew: Self {
        Page(template: .catalogueEditor) { request in
            try await request.permissions.previews.create.grant()
            let categories = try await request.commands.catalogueCategories.list().map(\.name)
            return CatalogueEditorViewModel(categories: categories)
        }
        .noStore()
    }

    static var catalogueItemEditor: Self {
        Page(template: .catalogueEditor) { request in
            guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
                throw Abort(.badRequest)
            }
            async let preview = request.commands.previews.fetch(previewID, for: .write)
            async let existingNotes = request.commands.notes.fetchByAttachment(previewID)
            let resolvedPreview = try await preview
            try await request.permissions.previews.edit.grant(resolvedPreview)
            let categoryNames = try await request.commands.catalogueCategories.list().map(\.name)
            let baseURL = request.baseURL
            let artworkURL: String? = resolvedPreview.image.map { "\(baseURL)/gallery/data/\($0.thumbnailKey)" }
            let notes = try await existingNotes
            return CatalogueEditorViewModel(
                previewID: previewID,
                url: resolvedPreview.externalLinks.first,
                title: resolvedPreview.primaryInfo,
                subtitle: resolvedPreview.secondaryInfo,
                artworkURL: artworkURL,
                category: resolvedPreview.catalogueCategory?.name ?? "",
                access: resolvedPreview.parentAccess,
                categories: categoryNames,
                notes: notes.map { NoteEditorViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access, language: $0.language) }
            )
        }
        .noStore()
    }
}

