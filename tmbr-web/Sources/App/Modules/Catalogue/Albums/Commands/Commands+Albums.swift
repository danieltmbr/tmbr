import Foundation
import CoreWeb
import CoreTmbr

extension Commands {
    var albums: Commands.Albums.Type { Commands.Albums.self }
}

extension Commands {

    struct Albums: CommandCollection, Sendable {

        let create: CommandFactory<AlbumInput, Album>

        let delete: CommandFactory<AlbumID, Void>

        let edit: CommandFactory<EditAlbumInput, Album>

        let fetch: CommandFactory<FetchParameters<AlbumID>, Album>

        let list: CommandFactory<PageInput, [Album]>

        let lookup: CommandFactory<String, Album?>

        let metadata: CommandFactory<URL, AlbumMetadata>

        let search: CommandFactory<String?, AlbumSearchResult>

        init(
            create: CommandFactory<AlbumInput, Album> = .createAlbum,
            delete: CommandFactory<AlbumID, Void> = .delete(\.albums),
            edit: CommandFactory<EditAlbumInput, Album> = .editAlbum,
            fetch: CommandFactory<FetchParameters<AlbumID>, Album> = .fetchAlbum,
            list: CommandFactory<PageInput, [Album]> = .listAlbums,
            lookup: CommandFactory<String, Album?> = .lookupAlbum,
            metadata: CommandFactory<URL, AlbumMetadata> = .fetchMetadata,
            search: CommandFactory<String?, AlbumSearchResult> = .searchAlbums
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.lookup = lookup
            self.metadata = metadata
            self.search = search
        }
    }
}
