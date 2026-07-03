import SwiftUI

/// A generic selectable row for one source bucket inside the Quotes filter list.
///
/// Both catalogue-category rows and the "Blog posts" row share this implementation;
/// the only variation is the `id` (category slug vs. `QuotesModel.blogPosts`), `name`,
/// and `systemImage`.
struct QuoteFilterRow: View {

    let id: String
    let name: String
    let systemImage: String

    @Quotes(\.selectedSources)
    private var selectedSources

    @Environment(\.selectQuoteSources)
    private var selectQuoteSources

    var body: some View {
        Button {
            selectQuoteSources([id], strategy: .toggle)
        } label: {
            HStack {
                Label(name, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedSources.contains(id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
