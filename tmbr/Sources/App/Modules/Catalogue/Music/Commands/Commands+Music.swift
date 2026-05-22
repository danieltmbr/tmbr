import Foundation
import Core

extension Commands {
    var music: Commands.Music.Type { Commands.Music.self }
}

extension Commands {

    struct Music: CommandCollection, Sendable {

        let search: CommandFactory<String?, MusicSearchResult>

        init(
            search: CommandFactory<String?, MusicSearchResult> = .searchMusic
        ) {
            self.search = search
        }
    }
}
