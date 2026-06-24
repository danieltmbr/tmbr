import Foundation
import OSLog
import CoreTmbr

/// One unit of sync: fetch from a paginated endpoint, hand the items to a sink (e.g. a store
/// upsert). Type-erased to `() async throws -> Void` so heterogeneous syncers can be grouped;
/// `label` identifies the endpoint in diagnostics.
public struct Syncer: Sendable {

    public let label: String
    let run: @Sendable () async throws -> Void

    public init(_ label: String = "", run: @escaping @Sendable () async throws -> Void) {
        self.label = label
        self.run = run
    }

    /// Couples a single-page load with a sink that consumes the loaded items.
    public init<Input, Element>(
        _ label: String = "",
        loader: RequestLoader<Input, PageResult<Element>>,
        from input: Input,
        into sink: @escaping @Sendable ([Element]) async throws -> Void
    ) where Input: Sendable, Element: Sendable {
        self.init(label) {
            try await sink(loader.load(from: input).items)
        }
    }
}

/// Runs a collection of independent `Syncer`s concurrently with **partial-success** semantics:
/// every syncer runs to completion regardless of others' failures; collected errors are logged by
/// label; the first error is rethrown so callers can surface a "couldn't update" state while
/// keeping every successfully-committed result visible.
public struct SyncGroup: Sendable {

    private let syncers: [Syncer]
    private let logger: Logger

    public init(_ syncers: [Syncer], logger: Logger = .sync) {
        self.syncers = syncers
        self.logger = logger
    }

    public func run() async throws {
        let failures: [(String, any Error)] = await withTaskGroup(of: (String, (any Error))?.self) { group in
            for syncer in syncers {
                group.addTask {
                    do { try await syncer.run(); return nil }
                    catch { return (syncer.label, error) }
                }
            }
            var collected: [(String, any Error)] = []
            for await failure in group {
                if let failure { collected.append(failure) }
            }
            return collected
        }
        for (label, error) in failures {
            logger.error("Sync '\(label)' failed: \(error)")
        }
        if let (_, error) = failures.first {
            throw error
        }
    }
}

public extension Logger {
    static let sync = Logger(subsystem: "me.tmbr", category: "sync")
}
