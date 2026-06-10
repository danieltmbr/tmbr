import Foundation
import SwiftData
import TmbrCore

@MainActor
public struct CreateNoteAction: Sendable {

    private let body: @MainActor (String, Access, CatalogueItemRecord, ModelContext) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (String, Access, CatalogueItemRecord, ModelContext) async -> Void = { _, _, _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine, context: ModelContext) {
        self.init { noteBody, access, item, ctx in
            let record = NoteRecord(
                body: noteBody,
                accessRaw: access.rawValue,
                languageRaw: Language.en.rawValue,
                syncState: .pendingCreate,
                attachmentPreviewID: item.id,
                attachmentTitle: item.title,
                attachmentSubtitle: item.subtitle,
                attachmentCategoryType: item.categoryType,
                attachmentSourceID: item.sourceID
            )
            ctx.insert(record)
            Task { try? await syncEngine.pushPendingNotes() }
        }
    }

    @MainActor public func callAsFunction(body: String, access: Access = .private, item: CatalogueItemRecord, context: ModelContext) async {
        await self.body(body, access, item, context)
    }
}
