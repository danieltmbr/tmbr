import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Blog", systemImage: "doc.text") {
                BlogTab()
            }
            Tab("Catalogue", systemImage: "square.grid.2x2") {
                CatalogueTab()
            }
            Tab(role: .search) {
                SearchTab()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}
