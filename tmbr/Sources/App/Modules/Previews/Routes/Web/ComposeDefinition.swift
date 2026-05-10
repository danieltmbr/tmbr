import AuthKit

struct ComposeDefinition: Sendable {

    struct Section: Sendable {
        let entries: [(ComposeAction, AuthPermission<Void>)]
    }

    let sections: [Section]

    var allEntries: [(ComposeAction, AuthPermission<Void>)] {
        sections.flatMap(\.entries)
    }

    func viewModel(allowed: Set<ComposeAction>) -> ComposePopupViewModel? {
        let filtered: [[ComposeAction]] = sections.compactMap { section in
            let pass = section.entries.map(\.0).filter { allowed.contains($0) }
            return pass.isEmpty ? nil : pass
        }
        guard !filtered.isEmpty else { return nil }
        return ComposePopupViewModel(
            sections: filtered.enumerated().map { idx, actions in
                ComposeSectionViewModel(
                    items: actions.map { ComposeItemViewModel(label: $0.label, icon: $0.icon, url: $0.url) },
                    hasSeparatorAfter: idx < filtered.count - 1
                )
            }
        )
    }

    static let standard = ComposeDefinition(sections: [
        Section(entries: [
            (ComposeAction(label: "Post", icon: .post, url: "/posts/new"), .createPost)
        ]),
        Section(entries: [
            (ComposeAction(label: "Book",    icon: .book,    url: "/books/new"),    .create("You don't have permission to add a book.")),
            (ComposeAction(label: "Movie",   icon: .movie,   url: "/movies/new"),   .create("You don't have permission to add a movie.")),
            (ComposeAction(label: "Podcast", icon: .podcast, url: "/podcasts/new"), .create("You don't have permission to add a podcast.")),
            (ComposeAction(label: "Song",    icon: .song,    url: "/songs/new"),    .create("You don't have permission to add a song."))
        ]),
        Section(entries: [
            (ComposeAction(label: "URL from clipboard", icon: .clipboard, url: "/catalogue/new"), AuthPermission())
        ])
    ])
}
