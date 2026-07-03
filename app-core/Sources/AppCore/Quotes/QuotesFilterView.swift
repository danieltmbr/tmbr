import SwiftUI

/// The Quotes-only filter sheet/popover.
///
/// Shows a "Sources" section (catalogue categories + Blog posts) and a "Show content
/// written in:" section (language filter). Presented from `QuotesTab`.
public struct QuotesFilterView: View {

    @Environment(\.dismiss)
    private var dismiss

    public init() {}

    public var body: some View {
        #if os(iOS)
        NavigationStack {
            List {
                QuoteSourcesSection()
                LanguageFilterSection()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .navigationTitle("Filter")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        #else
        VStack(spacing: 0) {
            HStack {
                Text("Filter")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            List {
                QuoteSourcesSection()
                LanguageFilterSection()
            }
        }
        .frame(minWidth: 200, maxHeight: 400)
        #endif
    }
}
