import SwiftUI
import CoreApi

/// Resolves a single `RequestLoader` directly from the `CatalogueItemLoaders` namespace.
///
/// Reads `\.apiBaseURL`, `\.urlSession`, and `\.itemLoaders` from the environment.
/// Returns `nil` when `apiBaseURL` is not set (Personal app / unconfigured).
///
/// Usage:
/// ```swift
/// @Loader(\.song) var loader   // RequestLoader<Int, SongResponse>?
/// ```
@MainActor @propertyWrapper
public struct Loader<Input: Sendable, Response: Decodable & Sendable>: DynamicProperty {

    @Environment(\.apiBaseURL) private var baseURL
    @Environment(\.urlSession) private var session
    @Environment(\.itemLoaders) private var loaders

    private let path: KeyPath<CatalogueItemLoaders, @Sendable (URL, URLSession) -> RequestLoader<Input, Response>>

    public init(_ path: KeyPath<CatalogueItemLoaders, @Sendable (URL, URLSession) -> RequestLoader<Input, Response>>) {
        self.path = path
    }

    public var wrappedValue: RequestLoader<Input, Response>? {
        guard let baseURL else { return nil }
        return loaders[keyPath: path](baseURL, session)
    }
}
