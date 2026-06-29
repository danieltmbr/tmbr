import SwiftUI

/// A non-disruptive one-liner row shown at the top of a populated catalogue list.
/// Displays refresh activity, a staleness indicator, or the last-updated time.
struct CatalogueStatusLine: View {

    @Catalogue(\.loading)
    private var loading

    @Catalogue(\.lastError)
    private var lastError

    @Catalogue(\.lastFetched)
    private var lastFetched

    var body: some View {
        statusContent
            .font(.caption)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var statusContent: some View {
        if loading == .refresh {
            Label("Updating\u{2026}", systemImage: "arrow.clockwise")
        } else if lastError != nil {
            if let date = lastFetched {
                Label {
                    Text("Couldn't update \u{00B7} ") + Text(date, format: .relative(presentation: .named))
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                }
            } else {
                Label("Couldn't update", systemImage: "exclamationmark.circle")
            }
        } else if let date = lastFetched {
            Text("Updated ") + Text(date, format: .relative(presentation: .named))
        }
    }
}
