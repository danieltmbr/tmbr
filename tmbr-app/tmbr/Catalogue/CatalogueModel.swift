import Foundation
import Observation

@MainActor
@Observable
final class CatalogueModel {

    private(set) var isSyncing = false
    private(set) var syncError: Error?
    private(set) var hasMoreItems = true
    private(set) var isLoadingMore = false

    let syncEngine: SyncEngine

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }
        do {
            try await syncEngine.runSync()
            hasMoreItems = true
        } catch {
            syncError = error
        }
    }

    func loadMoreItems() async {
        guard !isLoadingMore, hasMoreItems else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            hasMoreItems = try await syncEngine.fetchOlderCatalogueItems()
        } catch {}
    }
}
