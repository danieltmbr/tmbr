import Foundation

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
