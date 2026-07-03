import SwiftUI

public extension View {
    /// Injects the Preferences model and its language-selection action into the view subtree.
    ///
    /// Call this once at the composition root alongside `.blog(_:)` and `.catalogue(_:)`:
    /// ```swift
    /// ContentView()
    ///     .blog(blog)
    ///     .catalogue(catalogue)
    ///     .preferences(preferences)
    /// ```
    func preferences(_ model: PreferencesModel) -> some View {
        environment(model)
            .environment(\.selectLanguages, SelectLanguagesAction(model: model))
    }
}
