import Foundation
import Core

extension Commands {
    var songs: Commands.Songs.Type { Commands.Songs.self }
}

extension Commands {
    
    struct Songs: CommandCollection, Sendable {
        
        let create: CommandFactory<CreateSongInput, Song>
        
        let delete: CommandFactory<SongID, Void>
        
        let edit: CommandFactory<EditSongInput, Song>
        
        let fetch: CommandFactory<FetchParameters<SongID>, Song>
        
        init(
            create: CommandFactory<CreateSongInput, Song> = .createSong,
            delete: CommandFactory<SongID, Void> = .delete(\.songs),
            edit: CommandFactory<EditSongInput, Song> = .editSong,
            fetch: CommandFactory<FetchParameters<SongID>, Song> = .fetchSong
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
        }
    }
}
