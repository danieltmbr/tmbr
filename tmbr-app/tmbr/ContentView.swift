import SwiftUI

struct ContentView: View {

    @Environment(NetworkMonitor.self) private var networkMonitor

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
        .safeAreaInset(edge: .top, spacing: 0) {
            if !networkMonitor.isConnected {
                offlineBanner
            }
        }
    }

    private var offlineBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
            Text("Offline — changes will sync when connected")
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(.orange.gradient)
    }
}
