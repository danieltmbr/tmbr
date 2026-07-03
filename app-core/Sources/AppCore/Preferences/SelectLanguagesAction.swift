import Foundation
import TmbrCore

/// Toggles a single language in/out of the active language filter.
///
/// Follows the house Action pattern: one struct, one responsibility. Constructed with
/// `init(model:)` at the injection site; the nonisolated `init(_ body:)` supports
/// previews and testing with a stub closure.
@MainActor
public struct SelectLanguagesAction: Sendable {

    private let body: @MainActor (Language) -> Void

    nonisolated public init(_ body: @escaping @MainActor (Language) -> Void = { _ in }) {
        self.body = body
    }

    @MainActor
    public init(model: PreferencesModel) {
        self.init { language in
            if model.selectedLanguages.contains(language) {
                model.selectedLanguages.remove(language)
            } else {
                model.selectedLanguages.insert(language)
            }
        }
    }

    public func callAsFunction(_ language: Language) {
        body(language)
    }
}
