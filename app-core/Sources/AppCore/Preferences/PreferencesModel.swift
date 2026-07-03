import Foundation
import TmbrCore

/// Global, persisted user preferences.
///
/// Constructed once at the app layer and injected via `.preferences(_:)`. Use the `@Preferences`
/// property wrapper to read values in views; use the `selectLanguages` environment action to
/// toggle individual language filters.
///
/// Persists the language preference to `UserDefaults` using two boolean keys that are also
/// declared in the Reader app's `Settings.bundle`, so the iOS Settings.app pane and the macOS
/// Settings scene (⌘,) share the same source of truth.
@MainActor
@Observable
public final class PreferencesModel {

    // MARK: - UserDefaults keys (must match Settings.bundle Root.plist)

    static let languageEnKey = "language_en_enabled"
    static let languageHuKey = "language_hu_enabled"

    // MARK: - State

    /// The languages currently selected to show content for.
    ///
    /// Default is all languages (both `.en` and `.hu`). Removing a language hides content
    /// written in that language. An empty set (all deselected) acts as no filter — all content
    /// remains visible — so users can never blank out all content.
    public var selectedLanguages: Set<Language> {
        didSet { persist() }
    }

    // MARK: - Init

    public init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Self.languageEnKey: true,
            Self.languageHuKey: true,
        ])
        // Init doesn't trigger didSet, so we read directly.
        selectedLanguages = Self.read(from: defaults)
    }

    // MARK: - Public API

    /// Re-reads the stored preference from `UserDefaults`.
    ///
    /// Call this when the app transitions to `.active` scene phase so that edits made in iOS
    /// Settings.app or the macOS Settings scene are reflected without a full app relaunch.
    public func refreshFromDefaults() {
        selectedLanguages = Self.read(from: .standard)
    }

    // MARK: - Private

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(selectedLanguages.contains(.en), forKey: Self.languageEnKey)
        defaults.set(selectedLanguages.contains(.hu), forKey: Self.languageHuKey)
    }

    private static func read(from defaults: UserDefaults) -> Set<Language> {
        var result = Set<Language>()
        if defaults.bool(forKey: languageEnKey) { result.insert(.en) }
        if defaults.bool(forKey: languageHuKey) { result.insert(.hu) }
        return result
    }
}
