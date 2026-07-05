import SwiftUI

/// A standalone filter sheet showing only the language preference section.
///
/// Used by the Blog tab, which has no category filter. Catalogue and Quotes use
/// `CatalogueFilterView` (which embeds both the category list and this language section).
public struct LanguageFilterView: View {

    @Environment(\.dismiss)
    private var dismiss

    public init() {}

    public var body: some View {
        #if os(iOS)
        NavigationStack {
            List {
                LanguageFilterSection()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Language")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        #else
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Language")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            List {
                LanguageFilterSection()
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 280, height: 360)
        #endif
    }
}
