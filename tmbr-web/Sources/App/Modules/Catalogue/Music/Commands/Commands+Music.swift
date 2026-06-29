import Foundation
import WebCore

extension Commands {
    var music: Commands.Music.Type { Commands.Music.self }
}

extension Commands {

    struct Music: CommandCollection, Sendable {

        let search: CommandFactory<CatalogueQueryPayload, MusicSearchResult>

        init(
            search: CommandFactory<CatalogueQueryPayload, MusicSearchResult> = .searchMusic
        ) {
            self.search = search
        }
    }
}
