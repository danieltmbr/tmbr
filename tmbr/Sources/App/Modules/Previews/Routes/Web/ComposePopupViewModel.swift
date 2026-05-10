struct ComposeItemViewModel: Encodable, Sendable {
    let label: String
    let icon: Icon
    let url: String
}

struct ComposeSectionViewModel: Encodable, Sendable {
    let items: [ComposeItemViewModel]
    let hasSeparatorAfter: Bool
}

struct ComposePopupViewModel: Encodable, Sendable {

    let sections: [ComposeSectionViewModel]

    static let standard = ComposePopupViewModel(sections: [
        ComposeSectionViewModel(
            items: [
                ComposeItemViewModel(label: "Post", icon: .post, url: "/posts/new")
            ],
            hasSeparatorAfter: true
        ),
        ComposeSectionViewModel(
            items: [
                ComposeItemViewModel(label: "Book", icon: .book, url: "/books/new"),
                ComposeItemViewModel(label: "Movie", icon: .movie, url: "/movies/new"),
                ComposeItemViewModel(label: "Podcast", icon: .podcast, url: "/podcasts/new"),
                ComposeItemViewModel(label: "Song", icon: .song, url: "/songs/new")
            ],
            hasSeparatorAfter: true
        ),
        ComposeSectionViewModel(
            items: [
                ComposeItemViewModel(label: "URL from clipboard", icon: .clipboard, url: "/catalogue/new")
            ],
            hasSeparatorAfter: false
        )
    ])
}
