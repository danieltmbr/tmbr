import SwiftUI

public extension View {
    /// Injects the Preferences model and its language-selection action into the view subtree.
    ///
    /// Call this once at the composition root alongside `.catalogue(_:)` and `.quotes(_:)`:
    /// ```swift
    /// ContentView()
    ///     .catalogue(catalogue)
    ///     .quotes(quotes)
    ///     .preferences(preferences)
    /// ```
    func preferences(_ model: PreferencesModel) -> some View {
        environment(model)
            .environment(\.selectLanguages, SelectLanguagesAction(model: model))
            .environment(\.syncPreferences, SyncPreferencesAction(model: model))
    }
}
