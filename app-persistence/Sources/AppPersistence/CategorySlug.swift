import Foundation

/// An opaque token representing a catalogue category's slug.
///
/// Instances can only be obtained from a real `CatalogueCategoryRecord` via
/// `categorySlug`, preventing arbitrary strings from being passed as filter
/// selections. `rawValue` is intentionally internal so the UI layer treats it
/// as an identity token — comparable, `Hashable`, and `Set`-storable, but
/// never constructible from a literal.
public struct CategorySlug: Hashable, Sendable {
    let rawValue: String
    init(_ rawValue: String) { self.rawValue = rawValue }
}

public extension CatalogueCategoryRecord {
    /// The category's slug as a typed, opaque token.
    /// This is the only public way to obtain a `CategorySlug`.
    var categorySlug: CategorySlug { CategorySlug(slug) }
}
