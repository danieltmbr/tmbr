import Fluent
import TmbrCore

public protocol LanguageFilterable: Model {
    static var languageKeyPath: KeyPath<Self, FieldProperty<Self, Language>> { get }
}

public extension QueryBuilder where Model: LanguageFilterable {
    @discardableResult
    func languages(_ languages: [Language]?) -> Self {
        guard let languages, !languages.isEmpty else { return self }
        return group(.or) { or in
            languages.forEach { or.filter(Model.languageKeyPath == $0) }
        }
    }
}
