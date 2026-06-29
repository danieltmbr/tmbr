import SwiftUI
import SwiftData
import CoreApi

/// Resolves and assembles a single `CatalogueItemSyncer` from the `CatalogueItemSyncs`
/// recipe namespace.
///
/// Reads `\.apiBaseURL`, `\.urlSession`, `\.itemSyncs`, and `\.modelContext` from the
/// environment; resolves the selected recipe's loader (one loader, built exactly once per
/// access), then calls `recipe.assemble(loader:store:)` to produce the syncer. Returns a
/// no-op syncer when `apiBaseURL` is not set (Personal app / unconfigured — no networking).
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
    @Environment(\.itemSyncs) private var syncs
    @Environment(\.modelContext) private var context

    private let path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<ID, Response>>

    public init(_ path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<ID, Response>>) {
        self.path = path
    }

    public var wrappedValue: CatalogueItemSyncer<ID> {
        guard let baseURL else { return .init() }   // Personal / unconfigured → no-op
        let recipe = syncs[keyPath: path]
        let loader = recipe.loaderFactory(baseURL, session)
        return recipe.assemble(loader, CatalogueStore(context: context))
    }
}
