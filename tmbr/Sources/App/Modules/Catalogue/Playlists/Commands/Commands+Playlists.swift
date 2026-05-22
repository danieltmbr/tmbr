import Foundation
import Core

extension Commands {
    var playlists: Commands.Playlists.Type { Commands.Playlists.self }
}

extension Commands {

    struct Playlists: CommandCollection, Sendable {

        let create: CommandFactory<PlaylistInput, Playlist>

        let delete: CommandFactory<PlaylistID, Void>

        let edit: CommandFactory<EditPlaylistInput, Playlist>

        let fetch: CommandFactory<FetchParameters<PlaylistID>, Playlist>

        let search: CommandFactory<String?, PlaylistSearchResult>

        init(
            create: CommandFactory<PlaylistInput, Playlist> = .createPlaylist,
            delete: CommandFactory<PlaylistID, Void> = .delete(\.playlists),
            edit: CommandFactory<EditPlaylistInput, Playlist> = .editPlaylist,
            fetch: CommandFactory<FetchParameters<PlaylistID>, Playlist> = .fetchPlaylist,
            search: CommandFactory<String?, PlaylistSearchResult> = .searchPlaylists
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.search = search
        }
    }
}
