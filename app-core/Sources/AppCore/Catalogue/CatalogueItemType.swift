import Foundation
import AppPersistence

public enum CatalogueItemType: String, CaseIterable, Identifiable, Sendable {
    case song, album, playlist, book, podcast, movie

    public var id: String { rawValue }

    public var label: String { rawValue.capitalized }

    public var systemImage: String {
        switch self {
        case .song: "music.note"
        case .album: "music.note.square.stack"
        case .playlist: "music.note.list"
        case .book: "book.closed"
        case .podcast: "mic"
        case .movie: "film"
        }
    }
}

public extension PreviewRecord {
    /// The known catalogue type, or `nil` for orphan / user-defined categories.
    var category: CatalogueItemType? { CatalogueItemType(rawValue: categoryType) }
}
