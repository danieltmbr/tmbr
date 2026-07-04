import SwiftUI
import TmbrCore

/// A filter section displaying all available languages as toggleable rows.
///
/// Returns a `Section` for embedding inside a `List` or `Form`. Both the Catalogue/Quotes
/// filter sheet and the Blog filter sheet embed this section; the macOS Settings scene embeds
/// it inside a `Form`.
struct LanguageFilterSection: View {

    var body: some View {
        Section("Show content written in:") {
            ForEach(Language.allCases, id: \.self) { language in
                LanguageRow(language: language)
                    .listRowBackground(Color.clear)
            }
        }
    }
}
