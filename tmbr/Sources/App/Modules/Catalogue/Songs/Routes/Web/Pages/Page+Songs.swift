import Vapor
import Core
import Foundation

struct SongsViewModel: Encodable, Sendable {
    let compose: String?
    let term: String?
    let previews: [PreviewViewModel]
}

extension Template where Model == SongsViewModel {
    static let songs = Template(name: "Catalogue/Songs/songs")
}

extension Page {
    static var songs: Self {
        Page(template: .songs) { req in
            let term = try? req.query.get(String.self, at: "term")
            let input = PreviewQueryInput(term: term, types: [Song.previewType])
            async let composeURL: String? = (try? await req.permissions.songs.create()) != nil ? "/songs/new" : nil
            async let previewList = req.commands.previews.list(input)
            let baseURL = req.baseURL
            return SongsViewModel(
                compose: await composeURL,
                term: term,
                previews: try await previewList.map { PreviewViewModel(preview: $0, baseURL: baseURL) }
            )
        }
    }
}
