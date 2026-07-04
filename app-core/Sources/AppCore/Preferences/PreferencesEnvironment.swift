import SwiftUI

public extension EnvironmentValues {
    /// Toggles a single language in/out of the active filter. Default is a no-op.
    @Entry var selectLanguages: SelectLanguagesAction = SelectLanguagesAction()
    /// Re-reads preferences from UserDefaults. Default is a no-op.
    @Entry var syncPreferences: SyncPreferencesAction = SyncPreferencesAction()
}
