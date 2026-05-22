import Vapor
import Core
import Foundation

struct MusicEditorViewModel: Encodable, Sendable {
    let pageTitle: String
    let composeAction: String
}

extension Template where Model == MusicEditorViewModel {
    static let musicEditor = Template(name: "Catalogue/Music/music-editor")
}

extension Page {
    static var newMusic: Self {
        Page(template: .musicEditor) { req in
            let canSong = (try? await req.permissions.songs.create()) != nil
            let canAlbum = (try? await req.permissions.albums.create()) != nil
            let canPlaylist = (try? await req.permissions.playlists.create()) != nil
            guard canSong || canAlbum || canPlaylist else {
                throw Abort(.unauthorized)
            }
            return MusicEditorViewModel(
                pageTitle: "New music",
                composeAction: "/music/new"
            )
        }
    }
}
