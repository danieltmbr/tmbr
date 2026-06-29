import Foundation

/// An id-parameterised refresh capability injected per catalogue type. The body is provided at
/// the app layer (Reader/Author); the default is a no-op so CoreApp compiles without networking.
///
/// Generic over `ID` to cover typed items (`Int` source id) vs orphans (`UUID` preview id).
@MainActor
public struct CatalogueItemSyncer<ID: Sendable>: Sendable {

    private let body: @MainActor (ID) async throws -> Void

    nonisolated public init(_ body: @escaping @MainActor (ID) async throws -> Void = { _ in }) {
        self.body = body
    }

    public func callAsFunction(_ id: ID) async throws { try await body(id) }
}
