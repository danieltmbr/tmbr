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
        
        let metadata: CommandFactory<URL, SongMetadata>

        let search: CommandFactory<String?, SongSearchResult>

        init(
            create: CommandFactory<SongInput, Song> = .createSong,
            delete: CommandFactory<SongID, Void> = .delete(\.songs),
            edit: CommandFactory<EditSongInput, Song> = .editSong,
            fetch: CommandFactory<FetchParameters<SongID>, Song> = .fetchSong,
            metadata: CommandFactory<URL, SongMetadata> = .fetchMetadata,
            search: CommandFactory<String?, SongSearchResult> = .searchSongs
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.metadata = metadata
            self.search = search
        }
    }
}
