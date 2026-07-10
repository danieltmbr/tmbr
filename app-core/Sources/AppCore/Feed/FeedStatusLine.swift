import SwiftUI

/// A non-disruptive one-liner row shown at the top of a populated feed list.
/// Displays refresh activity, a failure indicator, or the last-updated time.
///
/// Self-contained: reads the nearest feed's state from `\.feedState` (scoped by
/// `.feedControls(_:retry:)`). Uses `Text(date, format:)` for relative dates so the time
/// auto-updates while on screen.
struct FeedStatusLine: View {

    @Environment(\.feedState)
    private var state

    var body: some View {
        statusContent
            .font(.caption)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private var statusContent: some View {
        if state.loading == .refresh {
            Label("Updating\u{2026}", systemImage: "arrow.clockwise")
        } else if state.lastError != nil {
            if let date = state.lastFetched {
                Label {
                    Text("Couldn't update \u{00B7} \(date, format: .relative(presentation: .named))")
                } icon: {
                    Image(systemName: "exclamationmark.circle")
                }
            } else {
                Label("Couldn't update", systemImage: "exclamationmark.circle")
            }
        } else if let date = state.lastFetched {
            Text("Updated \(date, format: .relative(presentation: .named))")
        }
        // else: EmptyView — no status to show yet
    }
}
