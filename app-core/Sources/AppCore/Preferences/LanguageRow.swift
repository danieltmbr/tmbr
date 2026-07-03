import SwiftUI
import TmbrCore

/// A single selectable row for a language option inside a filter list.
struct LanguageRow: View {

    let language: Language

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @Environment(\.selectLanguages)
    private var selectLanguages

    var body: some View {
        Button {
            selectLanguages(language)
        } label: {
            HStack {
                Text(language.displayName)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedLanguages.contains(language) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private extension Language {
    var displayName: String {
        switch self {
        case .en: "English"
        case .hu: "Hungarian"
        }
    }
}
