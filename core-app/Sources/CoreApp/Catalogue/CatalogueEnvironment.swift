import SwiftUI
import Foundation

public extension EnvironmentValues {
    @Entry var refreshCatalogue: CatalogueRefreshAction = CatalogueRefreshAction()

    // Networking config — decoupled from the recipe namespace so each value can be overridden
    // independently (e.g. tests inject a stub URLSession without touching baseURL).
    // `apiBaseURL == nil` is the on/off gate: Personal injects nothing → @Loader/.@Upserter no-op.
    @Entry var apiBaseURL: URL? = nil
    @Entry var urlSession: URLSession = .shared

    // Single recipe namespace for all catalogue item types. Each recipe carries its own loader
    // factory and store sink; @Loader and @Upserter both keypath into this one namespace.
    // Default provides real factories; tests override individual recipes via the memberwise init.
    @Entry var itemSyncs: CatalogueItemSyncs = .init()
}
