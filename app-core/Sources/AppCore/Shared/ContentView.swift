import SwiftUI

public struct ContentView: View {

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
#if !os(macOS)
            Tab(role: .search) {
                SearchTab()
            }
#endif
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
