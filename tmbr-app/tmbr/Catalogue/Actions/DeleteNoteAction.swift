import Foundation
import SwiftData

@MainActor
public struct DeleteNoteAction: Sendable {

    private let body: @MainActor (NoteRecord, ModelContext) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (NoteRecord, ModelContext) async -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine) {
        self.init { record, context in
            if record.serverID != nil {
                record.syncState = .pendingDelete
                Task { try? await syncEngine.pushPendingNotes() }
            } else {
                // Not yet on the server — safe to delete immediately without a server call.
                context.delete(record)
            }
        }
    }

    @MainActor public func callAsFunction(record: NoteRecord, context: ModelContext) async {
        await body(record, context)
    }
}
