import SwiftUI

public struct ContentView: View {

    @Environment(\.syncPreferences)
    private var syncPreferences

    @Environment(\.scenePhase)
    private var scenePhase

    public init() {}

    public var body: some View {
        TabView {
#if os(macOS)
            Tab(role: .search) {
                SearchTab()
            }
#endif
            Tab("Blog", systemImage: "doc.text") {
                BlogTab()
            }
            Tab("Catalogue", systemImage: "square.grid.2x2") {
                CatalogueTab()
            }
            Tab("Quotes", systemImage: "quote.bubble") {
                QuotesTab()
            }
#if !os(macOS)
            Tab(role: .search) {
                SearchTab()
            }
#endif
        }
        .tabViewStyle(.sidebarAdaptable)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { syncPreferences() }
        }
    }
}
