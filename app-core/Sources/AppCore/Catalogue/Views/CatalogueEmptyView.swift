import SwiftUI

/// Overlay shown when the catalogue list is empty, switching on the current load state.
struct CatalogueEmptyView: View {

    @Catalogue(\.loading)
    private var loading

    @Catalogue(\.lastError)
    private var lastError

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    var body: some View {
        if loading == .refresh {
            ProgressView()
        } else if let error = lastError {
            ContentUnavailableView {
                Label(error.title, systemImage: error.systemImage)
            } description: {
                Text(error.message)
            } actions: {
                Button("Try Again") { Task { await refreshCatalogue() } }
            }
        } else {
            ContentUnavailableView("Nothing here yet", systemImage: "square.grid.2x2")
        }
    }
}
