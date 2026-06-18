import Foundation
import CoreWeb
import CoreTmbr

extension Commands {
    var songs: Commands.Songs.Type { Commands.Songs.self }
}

extension Commands {
    
    struct Songs: CommandCollection, Sendable {

        let create: CommandFactory<SongInput, Song>

        let delete: CommandFactory<SongID, Void>

        let edit: CommandFactory<EditSongInput, Song>

        let fetch: CommandFactory<FetchParameters<SongID>, Song>

        let list: CommandFactory<PageInput, [Song]>

        let lookup: CommandFactory<String, Song?>

        let metadata: CommandFactory<URL, SongMetadata>

        let promote: CommandFactory<UUID, Song>

        let search: CommandFactory<String?, SongSearchResult>

        init(
            create: CommandFactory<SongInput, Song> = .createSong,
            delete: CommandFactory<SongID, Void> = .delete(\.songs),
            edit: CommandFactory<EditSongInput, Song> = .editSong,
            fetch: CommandFactory<FetchParameters<SongID>, Song> = .fetchSong,
            list: CommandFactory<PageInput, [Song]> = .listSongs,
            lookup: CommandFactory<String, Song?> = .lookupSong,
            metadata: CommandFactory<URL, SongMetadata> = .fetchMetadata,
            promote: CommandFactory<UUID, Song> = .promoteSong,
            search: CommandFactory<String?, SongSearchResult> = .searchSongs
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.lookup = lookup
            self.metadata = metadata
            self.promote = promote
            self.search = search
        }
    }
}
