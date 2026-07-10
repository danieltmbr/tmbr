import SwiftUI

/// A non-disruptive one-liner row for a catalogue item detail screen.
/// Twin of `FeedStatusLine` — same visuals, same states, but takes loading/lastError/lastFetched
/// as direct inputs rather than a `FeedModel` (item detail state isn't feed-backed).
struct CatalogueItemStatusLine: View {

    let loading: LoadingState?
    let lastError: LoadError?
    let lastFetched: Date?

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
                    Text("Couldn't update \u{00B7} \(date, format: .relative(presentation: .named))")
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                }
            } else {
                Label("Couldn't update", systemImage: "exclamationmark.circle")
            }
        } else if let date = lastFetched {
            Text("Updated \(date, format: .relative(presentation: .named))")
        }
    }
}
