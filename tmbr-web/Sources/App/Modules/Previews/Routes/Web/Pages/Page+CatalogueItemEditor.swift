import Vapor
import Foundation
import AuthKit
import Core
import TmbrCore

extension Page {
    static var catalogueItemEditor: Self {
        Page(template: .catalogueEditor) { request in
            guard let previewID = request.parameters.get("previewID", as: UUID.self) else {
                throw Abort(.badRequest)
            }
            async let preview = request.commands.previews.fetch(previewID, for: .write)
            async let existingNotes = request.commands.notes.fetchByAttachment(previewID)
            let resolvedPreview = try await preview
            try await request.permissions.previews.edit.grant(resolvedPreview)
            let categoryNames = ((try? await request.commands.catalogueCategories.list()) ?? []).map(\.name)
            let baseURL = request.baseURL
            let artworkURL: String? = resolvedPreview.image.map { "\(baseURL)/gallery/data/\($0.thumbnailKey)" }
            let notes = try await existingNotes
            return CatalogueNewViewModel(
                previewID: previewID,
                url: resolvedPreview.externalLinks.first,
                title: resolvedPreview.primaryInfo,
                subtitle: resolvedPreview.secondaryInfo,
                artworkURL: artworkURL,
                category: resolvedPreview.catalogueCategory?.name ?? "",
                access: resolvedPreview.parentAccess,
                categories: categoryNames,
                notes: notes.map { CatalogueNewViewModel.NoteViewModel(id: $0.id?.uuidString, body: $0.body, access: $0.access, language: $0.language) }
            )
        }
    }
}
