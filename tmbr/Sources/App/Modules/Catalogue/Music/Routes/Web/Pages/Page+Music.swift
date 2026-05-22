import Vapor
import Core
import Foundation

extension Template where Model == CatalogueListViewModel {
    static let music = Template(name: "Catalogue/list")
}

extension Page {
    static var music: Self {
        Page(template: .music) { req in
            let term = try? req.query.get(String.self, at: "term")
            async let composeURL: String? = {
                let canSong = (try? await req.permissions.songs.create()) != nil
                let canAlbum = (try? await req.permissions.albums.create()) != nil
                let canPlaylist = (try? await req.permissions.playlists.create()) != nil
                return (canSong || canAlbum || canPlaylist) ? "/music/new" : nil
            }()
            async let result = req.commands.music.search(term)
            let baseURL = req.baseURL
            let resolved = try await result
            return CatalogueListViewModel(
                compose: await composeURL,
                term: term,
                previews: resolved.previews.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
                    + resolved.noteMatches.map { PreviewViewModel(preview: $0, baseURL: baseURL, isNoteMatch: true) }
            )
        }
    }
}
