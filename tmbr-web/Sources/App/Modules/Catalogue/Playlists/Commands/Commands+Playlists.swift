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

        let list: CommandFactory<PageInput, [Playlist]>

        let metadata: CommandFactory<URL, PlaylistMetadata>

        let search: CommandFactory<String?, PlaylistSearchResult>

        init(
            create: CommandFactory<PlaylistInput, Playlist> = .createPlaylist,
            delete: CommandFactory<PlaylistID, Void> = .delete(\.playlists),
            edit: CommandFactory<EditPlaylistInput, Playlist> = .editPlaylist,
            fetch: CommandFactory<FetchParameters<PlaylistID>, Playlist> = .fetchPlaylist,
            list: CommandFactory<PageInput, [Playlist]> = .listPlaylists,
            metadata: CommandFactory<URL, PlaylistMetadata> = .fetchPlaylistMetadata,
            search: CommandFactory<String?, PlaylistSearchResult> = .searchPlaylists
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.metadata = metadata
            self.search = search
        }
    }
}
