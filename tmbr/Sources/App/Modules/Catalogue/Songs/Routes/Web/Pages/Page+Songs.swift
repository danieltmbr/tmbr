import Vapor
import Core
import Foundation

struct SongsViewModel: Encodable, Sendable {
    let previews: [PreviewViewModel]
}

extension Template where Model == SongsViewModel {
    static let songs = Template(name: "Catalogue/Songs/songs")
}

extension Page {
    static var songs: Self {
        Page(template: .songs) { req in
            let input = PreviewQueryInput(types: [Song.previewType])
            let previews = try await req.commands.previews.list(input)
            let baseURL = req.baseURL
            return SongsViewModel(previews: previews.map {
                PreviewViewModel(preview: $0, baseURL: baseURL)
            })
        }
    }
}
