import SwiftUI

/// A non-disruptive one-liner row shown at the top of a populated post list.
/// Displays refresh activity, a staleness indicator, or the last-updated time.
///
/// Uses `Text(date, format:)` for relative dates so the time auto-updates while the view is on screen.
struct BlogStatusLine: View {

    @Blog(\.loading)
    private var activeLoad

    @Blog(\.lastError)
    private var lastError

    @Blog(\.lastFetched)
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
        if activeLoad == .refresh {
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
        // else: EmptyView — no status to show yet
    }
}
