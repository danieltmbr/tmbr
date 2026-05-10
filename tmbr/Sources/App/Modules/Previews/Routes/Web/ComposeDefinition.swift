import AuthKit

struct ComposeDefinition: Sendable {

    struct Section: Sendable {
        let entries: [(ComposeAction, AuthPermission<Void>)]
    }

    let sections: [Section]

    var allEntries: [(ComposeAction, AuthPermission<Void>)] {
        sections.flatMap(\.entries)
    }

    func filtered(allowed: Set<ComposeAction>) -> ComposeDefinition {
        ComposeDefinition(sections: sections.compactMap { section in
            let entries = section.entries.filter { action, _ in allowed.contains(action) }
            return entries.isEmpty ? nil : Section(entries: entries)
        })
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
