import Foundation
import Observation

@MainActor
@Observable
final class BlogModel {

    private(set) var isSyncing = false
    private(set) var syncError: Error?

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
        } catch {
            syncError = error
        }
    }
}
