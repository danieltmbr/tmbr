import Foundation
import TmbrCore

@MainActor
public struct UpdatePostAction: Sendable {

    private let body: @MainActor (PostRecord, String, String, PostState) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (PostRecord, String, String, PostState) async -> Void = { _, _, _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine) {
        self.init { record, title, content, state in
            record.title = title
            record.content = content
            record.stateRaw = state.rawValue
            if record.syncState == .synced { record.syncState = .pendingUpdate }
            Task { try? await syncEngine.pushPendingPosts() }
        }
    }

    @MainActor public func callAsFunction(record: PostRecord, title: String, content: String, state: PostState) async {
        await body(record, title, content, state)
    }
}
