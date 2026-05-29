import Foundation

enum CatalogueItemType: String, CaseIterable, Identifiable {
    case song, album, playlist, book, podcast, movie

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var systemImage: String {
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
