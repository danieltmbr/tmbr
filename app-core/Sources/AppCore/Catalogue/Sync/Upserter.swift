import SwiftUI
import SwiftData
import AppApi

/// Resolves and assembles a `CatalogueItemSyncer` by composing the loader and upserter
/// for a single catalogue item type.
///
/// Reads `\.apiBaseURL`, `\.urlSession`, `\.itemLoaders`, `\.itemUpserters`, and `\.modelContext`
/// from the environment. The `CatalogueItemSyncs` recipe links the loader factory to its typed
/// store upsert function, ensuring their `Response` type always matches.
/// Returns a no-op syncer when `apiBaseURL` is not set (Personal app / unconfigured).
///
/// Usage:
/// ```swift
/// @Upserter(\.song) var syncer     // CatalogueItemSyncer<Int>
/// @Upserter(\.orphan) var syncer   // CatalogueItemSyncer<UUID>
/// ```
@MainActor @propertyWrapper
public struct Upserter<ID: Sendable, Response: Decodable & Sendable>: DynamicProperty {

    @Environment(\.apiBaseURL) private var baseURL
    @Environment(\.urlSession) private var session
    @Environment(\.itemLoaders) private var loaders
    @Environment(\.itemUpserters) private var upserters
    @Environment(\.modelContext) private var context

    private let path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<ID, Response>>

    private static var syncs: CatalogueItemSyncs { .init() }

    public init(_ path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<ID, Response>>) {
        self.path = path
    }

    public var wrappedValue: CatalogueItemSyncer<ID> {
        guard let baseURL else { return .init() }   // Personal / unconfigured → no-op
        let recipe = Self.syncs[keyPath: path]
        let loader = loaders[keyPath: recipe.loaderPath](baseURL, session)
        let upsert = upserters[keyPath: recipe.upserterPath]
        let store  = CatalogueStore(context: context)
        return CatalogueItemSyncer { [label = recipe.label] id in
            try await Syncer(label, loader: loader, from: id) { try await upsert(store, $0) }.run()
        }
    }
}
