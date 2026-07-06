import Foundation
import OSLog
import AppPersistence

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

    /// Categories currently active in the filter. Empty = no filter (show all).
    public var selectedCategories: Set<CatalogueCategory> = []

    // MARK: - Dependencies

    private let _refresh: @Sendable () async throws -> Void

    /// Per-app seam for catalogue search. Called with the current search term; should fetch
    /// matching catalogue items and notes from the server and upsert them into the local store.
    private let _search: @Sendable (String) async throws -> Void

    public init(
        refresh: @escaping @Sendable () async throws -> Void = {},
        search: @escaping @Sendable (String) async throws -> Void = { _ in }
    ) {
        self._refresh = refresh
        self._search = search
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

    // MARK: - Search

    /// Fires the injected search closure with `term`. Sets `loading = .refresh` while in flight.
    public func search(term: String) async {
        guard loading == nil else { return }
        loading = .refresh
        defer { loading = nil }
        do {
            try await _search(term)
        } catch {
            Logger.catalogue.error("Catalogue search failed: \(error)")
            lastError = LoadError(error)
        }
    }
}
