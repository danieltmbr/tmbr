import SwiftUI

/// Overlay shown when the quotes list is empty, switching on the current catalogue load state.
struct QuotesEmptyView: View {

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
            ContentUnavailableView("Nothing here yet", systemImage: "quote.bubble")
        }
    }
}
