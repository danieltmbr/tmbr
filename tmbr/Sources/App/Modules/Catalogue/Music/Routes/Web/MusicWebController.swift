import Vapor
import Core

struct MusicMetadataResponse: Content, Sendable {
    let musicType: String
    let title: String?
    let artist: String?
    let description: String?
    let artwork: String?
    let releaseDate: String?
    let genre: String?
    let tracks: [TrackMetadata]?
}

struct MusicWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        let musicRoute = routes.grouped("music")
        let recoveringRoute = musicRoute.grouped(RecoverMiddleware())

        recoveringRoute.get(page: .music)
        recoveringRoute.get("new", page: .newMusic)

        musicRoute.get("metadata", use: metadata)
    }

    @Sendable
    private func metadata(_ request: Request) async throws -> MusicMetadataResponse {
        let urlString = try request.query.get(String.self, at: "url")
        guard let url = URL(string: urlString) else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }

        // Detect type from URL path before fetching (avoids double network call)
        let path = url.path
        if path.contains("/playlist/") || path.contains("/playlist") {
            let playlist = try await request.commands.playlists.metadata(url)
            return MusicMetadataResponse(
                musicType: "playlist",
                title: playlist.title,
                artist: nil,
                description: playlist.description,
                artwork: playlist.artwork,
                releaseDate: nil,
                genre: nil,
                tracks: playlist.tracks
            )
        } else if url.query?.contains("i=") == true {
            // Apple Music song link (?i=trackID)
            let song = try await request.commands.songs.metadata(url)
            return MusicMetadataResponse(
                musicType: "song",
                title: song.title,
                artist: song.artist,
                description: nil,
                artwork: song.artwork,
                releaseDate: song.releaseDate,
                genre: nil,
                tracks: nil
            )
        } else if path.contains("/album/") {
            let album = try await request.commands.albums.metadata(url)
            return MusicMetadataResponse(
                musicType: "album",
                title: album.title,
                artist: album.artist,
                description: nil,
                artwork: album.artwork,
                releaseDate: album.releaseDate,
                genre: nil,
                tracks: album.tracks
            )
        }

        // Unknown — return minimal response; frontend shows manual type selector
        return MusicMetadataResponse(
            musicType: "unknown",
            title: nil,
            artist: nil,
            description: nil,
            artwork: nil,
            releaseDate: nil,
            genre: nil,
            tracks: nil
        )
    }
}
