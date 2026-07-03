import SwiftUI

/// The preferences screen — used in the macOS Settings scene (⌘,).
///
/// Reads `PreferencesModel` from the environment (injected by the app layer via `.preferences(_:)`).
public struct PreferencesView: View {

    public init() {}

    public var body: some View {
        Form {
            LanguageFilterSection()
        }
        .formStyle(.grouped)
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 160)
        #endif
    }
}
