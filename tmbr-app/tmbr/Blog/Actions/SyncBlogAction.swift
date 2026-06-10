import Foundation

@MainActor
public struct SyncBlogAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    @MainActor public init(model: BlogModel) {
        self.init { await model.sync() }
    }

    @MainActor public func callAsFunction() async { await body() }
}
