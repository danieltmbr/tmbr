import WebAuth

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
            (.post,      .createPost)
        ]),
        Section(entries: [
            (.book,    .create("You don't have permission to add a book.")),
            (.movie,   .create("You don't have permission to add a movie.")),
            (.podcast, .create("You don't have permission to add a podcast.")),
            (.song,    .create("You don't have permission to add a song."))
        ]),
        Section(entries: [
            (.clipboard, AuthPermission())
        ])
    ])

    static let music = ComposeDefinition(sections: [
        Section(entries: [
            (.song,     .create("You don't have permission to add a song.")),
            (.album,    .create("You don't have permission to add an album.")),
            (.playlist, .create("You don't have permission to add a playlist."))
        ])
    ])

    static let book     = ComposeDefinition(sections: [Section(entries: [(.book,     .create("You don't have permission to add a book."))])])
    static let movie    = ComposeDefinition(sections: [Section(entries: [(.movie,    .create("You don't have permission to add a movie."))])])
    static let podcast  = ComposeDefinition(sections: [Section(entries: [(.podcast,  .create("You don't have permission to add a podcast."))])])
    static let song     = ComposeDefinition(sections: [Section(entries: [(.song,     .create("You don't have permission to add a song."))])])
    static let album    = ComposeDefinition(sections: [Section(entries: [(.album,    .create("You don't have permission to add an album."))])])
    static let playlist = ComposeDefinition(sections: [Section(entries: [(.playlist, .create("You don't have permission to add a playlist."))])])
}
