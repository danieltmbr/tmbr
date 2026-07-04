import SwiftUI
import AppPersistence

/// A selectable row for one source bucket inside the Quotes filter list.
///
/// Both catalogue-category rows and the "Blog posts" row share this implementation;
/// the only variation is the `source` filter value, `name`, and `systemImage`.
struct QuoteFilterRow: View {

    let source: QuoteSourceFilter
    let name: String
    let systemImage: String

    @Quotes(\.selectedSources)
    private var selectedSources

    @Environment(\.selectQuoteSources)
    private var selectQuoteSources

    var body: some View {
        Button {
            selectQuoteSources([source], strategy: .toggle)
        } label: {
            HStack {
                Label(name, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSources.contains(source) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
