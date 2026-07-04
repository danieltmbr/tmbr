import Foundation

/// Re-reads preferences from `UserDefaults` — call when the scene becomes active so that
/// edits made in iOS Settings.app or the macOS Settings scene are reflected immediately.
@MainActor
public struct SyncPreferencesAction: Sendable {

    private let body: @MainActor () -> Void

    nonisolated public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    @MainActor
    public init(model: PreferencesModel) {
        self.init { model.sync() }
    }

    public func callAsFunction() {
        body()
    }
}
