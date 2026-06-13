import Foundation
import TmbrCore

@MainActor
public struct UpdateNoteAction: Sendable {

    private let body: @MainActor (NoteRecord, String, Access) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (NoteRecord, String, Access) async -> Void = { _, _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine) {
        self.init { record, newBody, access in
            record.body = newBody
            record.accessRaw = access.rawValue
            if record.syncState == .synced { record.syncState = .pendingUpdate }
            Task { try? await syncEngine.pushPendingNotes() }
        }
    }

    @MainActor public func callAsFunction(record: NoteRecord, body: String, access: Access) async {
        await self.body(record, body, access)
    }
}
