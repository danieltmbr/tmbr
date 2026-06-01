import SwiftUI

struct ContentView: View {
    var body: some View {
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
