import Foundation

/// Re-fires page 1 of the active feed session — the env-injected seam behind `FeedEmptyView`'s
/// "Try Again" button. Wired by `.feedControls(_:retry:)`; the owning list supplies the closure
/// so retry re-runs whichever mode is active (browse refresh or search).
@MainActor
public struct FeedRetryAction: Sendable {

    private let body: @MainActor () async -> Void

    nonisolated public init(_ body: @escaping @MainActor () async -> Void = {}) {
        self.body = body
    }

    public func callAsFunction() async { await body() }
}
