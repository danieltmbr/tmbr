import Foundation

public enum CatalogueCategoryKind: String, Codable, CaseIterable, Sendable {
    case entry       // model-backed items visible in the feed: song, album, book, movie, playlist, podcast
    case promotable  // shallow placeholder awaiting promotion: track
    case orphan      // user-defined, no backing model: recipe, guide, link, …
    case virtual     // display-only grouping of related catalogue types, e.g. music → song/album/playlist
}

extension CatalogueCategoryKind {
    /// True for shallow placeholder items (currently: track) that cannot own Notes
    /// and are expected to be promoted to a first-class catalogue item.
    /// Use this instead of checking `preview.parentID != nil` — orphan and virtual items
    /// also have a nil parentID but are not shallow and can have notes.
    public var isShallow: Bool { self == .promotable }
}
