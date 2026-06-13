import Foundation
import Observation

@MainActor
@Observable
final class BlogModel {

    private(set) var isSyncing = false
    private(set) var syncError: Error?
    private(set) var hasMorePosts = true
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
            hasMorePosts = true   // reset after a fresh sync
        } catch {
            syncError = error
        }
    }

    func loadMorePosts() async {
        guard !isLoadingMore, hasMorePosts else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            hasMorePosts = try await syncEngine.fetchOlderPosts()
        } catch {
            // load-more failures are silent — user can scroll up and the existing data remains
        }
    }
}
