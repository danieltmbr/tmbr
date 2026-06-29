import SwiftUI
import CoreApi

/// Resolves a single `RequestLoader` from the `CatalogueItemSyncs` recipe namespace.
///
/// Reads `\.apiBaseURL`, `\.urlSession`, and `\.itemSyncs` from the environment; invokes the
/// selected recipe's `loaderFactory` with those values. Returns `nil` when `apiBaseURL` is
/// not set (Personal app / unconfigured).
///
/// Usage:
/// ```swift
/// @Loader(\.song) var loader   // RequestLoader<Int, SongResponse>?
/// ```
@MainActor @propertyWrapper
public struct Loader<Input: Sendable, Response: Decodable & Sendable>: DynamicProperty {

    @Environment(\.apiBaseURL) private var baseURL
    @Environment(\.urlSession) private var session
    @Environment(\.itemSyncs) private var syncs

    private let path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<Input, Response>>

    public init(_ path: KeyPath<CatalogueItemSyncs, CatalogueItemSync<Input, Response>>) {
        self.path = path
    }

    public var wrappedValue: RequestLoader<Input, Response>? {
        guard let baseURL else { return nil }
        return syncs[keyPath: path].loaderFactory(baseURL, session)
    }
}
