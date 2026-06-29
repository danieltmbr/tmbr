import Foundation
import OSLog

/// Headless model for a catalogue item detail screen — tracks per-item refresh activity and
/// outcome. Mirrors `CatalogueModel`'s shape (loading/lastError/lastFetched) but is driven by
/// the `CatalogueItemRefresh` published up from the active type section via `PreferenceKey`.
///
/// Owned by `CatalogueItemDetailView`; sections stay display-only.
@MainActor
@Observable
public final class CatalogueItemDetailModel {

    /// The visible section's published "how to refresh me" (id already bound).
    /// Set via `setSyncer(_:)` from `onPreferenceChange`.
    var refresh: CatalogueItemRefresh?

    public private(set) var loading: LoadingState?
    public private(set) var lastError: LoadError?
    public private(set) var lastFetched: Date?

    public init() {}

    /// Called by `onPreferenceChange` when the active section publishes a new refresh closure.
    func setRefresh(_ value: CatalogueItemRefresh?) {
        refresh = value
    }

    /// Runs the active section's refresh; updates loading/error/lastFetched.
    /// Called by `.refreshable` — errors are captured into `lastError`, never thrown to the caller.
    public func run() async {
        guard let refresh, loading == nil else { return }
        loading = .refresh
        defer { loading = nil }
        do {
            try await refresh.run()
            lastFetched = .now
            lastError = nil
        } catch {
            Logger.sync.error("Item refresh failed: \(error)")
            lastError = LoadError(error)
        }
    }
}
