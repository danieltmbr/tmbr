import Foundation

/// An opaque identity token for a catalogue category.
///
/// From the consumer's perspective this IS the category — a `Hashable`, `Set`-storable
/// value that can be held and compared without knowing the underlying storage key.
/// Constructible only from a real `CatalogueCategoryRecord`, so arbitrary strings
/// cannot be smuggled in as filter selections.
public struct CatalogueCategory: Hashable, Sendable {
    let rawValue: String
    init(_ rawValue: String) { self.rawValue = rawValue }

    /// Creates a `CatalogueCategory` from an authoritative record.
    /// This is the only public way to obtain a value.
    public init(_ record: CatalogueCategoryRecord) {
        self.init(record.slug)
    }
}
