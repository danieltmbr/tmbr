import Foundation
import SwiftData

@MainActor
public struct DeletePostAction: Sendable {

    private let body: @MainActor (PostRecord, ModelContext) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (PostRecord, ModelContext) async -> Void = { _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine) {
        self.init { record, context in
            if record.serverID != nil {
                record.syncState = .pendingDelete
                Task { try? await syncEngine.pushPendingPosts() }
            } else {
                context.delete(record)
            }
        }
    }

    @MainActor public func callAsFunction(record: PostRecord, context: ModelContext) async {
        await body(record, context)
    }
}
