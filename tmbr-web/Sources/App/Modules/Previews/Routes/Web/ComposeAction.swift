struct ComposeAction: Hashable, Sendable {
    let label: String
    let icon: Icon
    let url: String
}

extension ComposeAction {
    static let post      = ComposeAction(label: "Post",               icon: .textPage,           url: "/posts/new")
    static let book      = ComposeAction(label: "Book",               icon: .bookClosed,         url: "/books/new")
    static let movie     = ComposeAction(label: "Movie",              icon: .movieclapper,       url: "/movies/new")
    static let podcast   = ComposeAction(label: "Podcast",            icon: .microphone,         url: "/podcasts/new")
    static let song      = ComposeAction(label: "Song",               icon: .musicNote,          url: "/songs/new")
    static let album     = ComposeAction(label: "Album",              icon: .musicNoteSquareStack, url: "/albums/new")
    static let playlist  = ComposeAction(label: "Playlist",           icon: .musicNoteList,      url: "/playlists/new")
    static let clipboard = ComposeAction(label: "URL from clipboard", icon: .documentOnClipboard, url: "/catalogue/new")
}
