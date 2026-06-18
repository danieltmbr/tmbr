import Foundation

/// Headless model for the Blog tab. Holds only refresh `phase` — the list itself comes from `@Query`.
///
/// The **per-app seam** is the injected `refresh` closure: Reader fetches public posts + upserts;
/// Author runs its `SyncEngine`; Personal is a no-op. `CoreApp` stays networking-free — it only knows
/// "run this async operation and track its phase".
@MainActor
@Observable
public final class BlogModel {

    public private(set) var phase: LoadPhase = .idle

    private let _refresh: @Sendable () async throws -> Void

    public init(refresh: @escaping @Sendable () async throws -> Void = {}) {
        self._refresh = refresh
    }

    public func refresh() async {
        phase = .loading
        do {
            try await _refresh()
            phase = .loaded
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
