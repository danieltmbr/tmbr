import Foundation
import Core

extension Commands {
    var albums: Commands.Albums.Type { Commands.Albums.self }
}

extension Commands {

    struct Albums: CommandCollection, Sendable {

        let create: CommandFactory<AlbumInput, Album>

        let delete: CommandFactory<AlbumID, Void>

        let edit: CommandFactory<EditAlbumInput, Album>

        let fetch: CommandFactory<FetchParameters<AlbumID>, Album>

        let lookup: CommandFactory<String, Album?>

        let metadata: CommandFactory<URL, AlbumMetadata>

        let search: CommandFactory<String?, AlbumSearchResult>

        init(
            create: CommandFactory<AlbumInput, Album> = .createAlbum,
            delete: CommandFactory<AlbumID, Void> = .delete(\.albums),
            edit: CommandFactory<EditAlbumInput, Album> = .editAlbum,
            fetch: CommandFactory<FetchParameters<AlbumID>, Album> = .fetchAlbum,
            lookup: CommandFactory<String, Album?> = .lookupAlbum,
            metadata: CommandFactory<URL, AlbumMetadata> = .fetchMetadata,
            search: CommandFactory<String?, AlbumSearchResult> = .searchAlbums
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.lookup = lookup
            self.metadata = metadata
            self.search = search
        }
    }
}
