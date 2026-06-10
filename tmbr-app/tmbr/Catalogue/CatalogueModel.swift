import Foundation
import Observation

@MainActor
@Observable
final class CatalogueModel {

    private(set) var isSyncing = false
    private(set) var syncError: Error?

    private let syncEngine: SyncEngine

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }
        do {
            try await syncEngine.syncDelta()
        } catch {
            syncError = error
        }
    }
}
