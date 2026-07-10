import SwiftUI
import AppPersistence
import SwiftData
import AppApi

/// Resolves and assembles a `CatalogueItemSyncer` by composing the loader and upserter
/// for a single catalogue item type.
///
/// Reads `\.apiBaseURL`, `\.urlSession`, `\.itemLoaders`, `\.itemUpserters`, and `\.modelContext`
/// from the environment. The `CatalogueItemSyncDescriptor` links the loader factory to its typed
/// store upsert function, ensuring their `Response` type always matches.
/// Returns a no-op syncer when `apiBaseURL` is not set (Personal app / unconfigured).
///
/// Usage:
/// ```swift
/// @Upserter(.song) var syncer     // CatalogueItemSyncer<Int>
/// @Upserter(.orphan) var syncer   // CatalogueItemSyncer<UUID>
/// ```
@MainActor @propertyWrapper
public struct Upserter<ID: Sendable, Response: Decodable & Sendable>: DynamicProperty {

    @Environment(\.apiBaseURL) private var baseURL
    
    @Environment(\.urlSession) private var session
    
    @Environment(\.itemLoaders) private var loaders
    
    @Environment(\.itemUpserters) private var upserters
    
    @Environment(\.modelContext) private var context

    private let descriptor: CatalogueItemSyncDescriptor<ID, Response>

    public init(
        _ descriptor: CatalogueItemSyncDescriptor<ID, Response>
    )  {
        self.descriptor = descriptor
    }

    public var wrappedValue: CatalogueItemSyncer<ID> {
        guard let baseURL else { return .init() } 
        let loader = loaders[keyPath: descriptor.loaderPath](baseURL, session)
        let upsert = upserters[keyPath: descriptor.upserterPath]
        let store  = CatalogueStore(context: context)
        return CatalogueItemSyncer { [label = descriptor.label] id in
            try await Syncer(label, loader: loader, from: id) { try await upsert(store, $0) }.run()
        }
    }
}
