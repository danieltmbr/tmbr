import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BlogTab()
            CatalogueTab()
            SearchTab()
        }
    }
}
