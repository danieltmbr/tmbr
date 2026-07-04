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
    
    public struct Keys {
        let languageEn: String
        
        let languageHu: String
        
        public init(
            languageEn: String = "language_en_enabled",
            languageHu: String = "language_hu_enabled"
        ) {
            self.languageEn = languageEn
            self.languageHu = languageHu
        }
    }

    // MARK: - State

    /// The languages currently selected to show content for.
    ///
    /// Default is all languages (both `.en` and `.hu`). Removing a language hides content
    /// written in that language. An empty set (all deselected) acts as no filter — all content
    /// remains visible — so users can never blank out all content.
    public var selectedLanguages: Set<Language> {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    
    private let keys: Keys

    // MARK: - Init

    public init(
        defaults: UserDefaults = .standard,
        keys: Keys = Keys()
    ) {
        self.defaults = defaults
        self.keys = keys
        defaults.register(defaults: [
            keys.languageEn: true,
            keys.languageHu: true,
        ])
        // Init doesn't trigger didSet, so we read directly.
        selectedLanguages = Self.read(from: defaults, with: keys)
    }

    // MARK: - Public API

    /// Re-reads the stored preference from `UserDefaults`.
    ///
    /// Call this when the app transitions to `.active` scene phase so that edits made in iOS
    /// Settings.app or the macOS Settings scene are reflected without a full app relaunch.
    public func sync() {
        selectedLanguages = Self.read(from: defaults, with: keys)
    }

    // MARK: - Private

    private func persist() {
        defaults.set(selectedLanguages.contains(.en), forKey: keys.languageEn)
        defaults.set(selectedLanguages.contains(.hu), forKey: keys.languageHu)
    }

    private static func read(
        from defaults: UserDefaults,
        with keys: Keys
    ) -> Set<Language> {
        var result = Set<Language>()
        if defaults.bool(forKey: keys.languageEn) { result.insert(.en) }
        if defaults.bool(forKey: keys.languageHu) { result.insert(.hu) }
        return result
    }
}
