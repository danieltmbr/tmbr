import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {

    private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = connected
                // Trigger a sync when connectivity is restored.
                if !wasConnected && connected {
                    NotificationCenter.default.post(name: .connectivityRestored, object: nil)
                }
            }
        }
        monitor.start(queue: .global(qos: .utility))
    }
}

extension Notification.Name {
    static let connectivityRestored = Notification.Name("me.tmbr.connectivityRestored")
}
