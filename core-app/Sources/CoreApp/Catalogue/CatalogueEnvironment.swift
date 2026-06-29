import SwiftUI
import Foundation

public extension EnvironmentValues {
    @Entry var refreshCatalogue: CatalogueRefreshAction = CatalogueRefreshAction()

    // Networking config — `apiBaseURL == nil` is the on/off gate: Personal injects nothing
    // → @Loader returns nil, @Upserter returns a no-op syncer.
    @Entry var apiBaseURL: URL? = nil
    @Entry var urlSession: URLSession = .shared

    // Network seam: factories keyed by item type. Tests/previews substitute a stub factory
    // (e.g. a RequestLoader that never hits the network) for one type while leaving the rest real.
    @Entry var itemLoaders: CatalogueItemLoaders = .init()

    // Persistence seam: typed store-upsert closures. Tests/previews substitute a spy for one
    // type to assert the right response reaches the right store method.
    @Entry var itemUpserters: CatalogueItemUpserters = .init()
}
