import Foundation
import SwiftData
import TmbrCore

@MainActor
public struct CreatePostAction: Sendable {

    private let body: @MainActor (String, String, ModelContext) async -> Void

    nonisolated public init(_ body: @escaping @MainActor (String, String, ModelContext) async -> Void = { _, _, _ in }) {
        self.body = body
    }

    @MainActor public init(syncEngine: SyncEngine) {
        self.init { title, content, context in
            let record = PostRecord(
                title: title,
                content: content,
                stateRaw: PostState.draft.rawValue,
                languageRaw: Language.en.rawValue,
                syncState: .pendingCreate
            )
            context.insert(record)
            Task { try? await syncEngine.pushPendingPosts() }
        }
    }

    @MainActor public func callAsFunction(title: String, content: String, context: ModelContext) async {
        await body(title, content, context)
    }
}
