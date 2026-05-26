struct ComposeAction: Hashable, Sendable {
    let label: String
    let icon: Icon
    let url: String
}

extension ComposeAction {
    static let post      = ComposeAction(label: "Post",               icon: .post,      url: "/posts/new")
    static let book      = ComposeAction(label: "Book",               icon: .book,      url: "/books/new")
    static let movie     = ComposeAction(label: "Movie",              icon: .movie,     url: "/movies/new")
    static let podcast   = ComposeAction(label: "Podcast",            icon: .podcast,   url: "/podcasts/new")
    static let song      = ComposeAction(label: "Song",               icon: .song,      url: "/songs/new")
    static let album     = ComposeAction(label: "Album",              icon: .album,     url: "/albums/new")
    static let playlist  = ComposeAction(label: "Playlist",           icon: .playlist,  url: "/playlists/new")
    static let clipboard = ComposeAction(label: "URL from clipboard", icon: .clipboard, url: "/catalogue/new")
}
