import Foundation
import Core

extension Commands {
    var songs: Commands.Songs.Type { Commands.Songs.self }
}

extension Commands {
    
    struct Songs: CommandCollection, Sendable {

        let create: CommandFactory<SongInput, Song>

        let delete: CommandFactory<SongID, Void>

        let edit: CommandFactory<EditSongInput, Song>

        let fetch: CommandFactory<FetchParameters<SongID>, Song>

        let lookup: CommandFactory<String, Song?>

        let metadata: CommandFactory<URL, SongMetadata>

        let promote: CommandFactory<UUID, Song>

        let promoteCreate: CommandFactory<SongInput, Song>

        let search: CommandFactory<String?, SongSearchResult>

        init(
            create: CommandFactory<SongInput, Song> = .createSong,
            delete: CommandFactory<SongID, Void> = .delete(\.songs),
            edit: CommandFactory<EditSongInput, Song> = .editSong,
            fetch: CommandFactory<FetchParameters<SongID>, Song> = .fetchSong,
            lookup: CommandFactory<String, Song?> = .lookupSong,
            metadata: CommandFactory<URL, SongMetadata> = .fetchMetadata,
            promote: CommandFactory<UUID, Song> = .promoteSong,
            promoteCreate: CommandFactory<SongInput, Song> = .promoteCreate,
            search: CommandFactory<String?, SongSearchResult> = .searchSongs
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.lookup = lookup
            self.metadata = metadata
            self.promote = promote
            self.promoteCreate = promoteCreate
            self.search = search
        }
    }
}
