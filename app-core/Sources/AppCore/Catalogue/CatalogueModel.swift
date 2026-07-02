import Foundation
import OSLog

/// Headless model for the Catalogue tab — tracks refresh activity and outcome; the list comes from `@Query`.
/// The injected `refresh` closure is the per-app seam (Reader fetch+upsert / Author SyncEngine / no-op).
@MainActor
@Observable
public final class CatalogueModel {

    // MARK: - Public state

    /// Non-nil while a refresh is in flight.
    public private(set) var loading: LoadingState?

    /// The error from the last refresh attempt; `nil` after a successful refresh.
    public private(set) var lastError: LoadError?

    /// When the last successful refresh completed.
    public private(set) var lastFetched: Date?

    /// Slugs of the categories currently active in the filter. Empty = no filter (show all).
    public var selectedCategorySlugs: Set<String> = []

    // MARK: - Dependencies

    private let _refresh: @Sendable () async throws -> Void

    public init(refresh: @escaping @Sendable () async throws -> Void = {}) {
        self._refresh = refresh
    }

    // MARK: - Refresh

    public func refresh() async {
        guard loading == nil else { return }
        loading = .refresh
        defer { loading = nil }
        do {
            try await _refresh()
            lastFetched = .now
            lastError = nil
        } catch {
            Logger.catalogue.error("Catalogue refresh failed: \(error)")
            lastError = LoadError(error)
        }
    }
}
