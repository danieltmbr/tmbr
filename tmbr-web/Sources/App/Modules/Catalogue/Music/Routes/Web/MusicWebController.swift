import Vapor
import WebCore

struct MusicMetadataResponse: Content, Sendable {
    
    let artist: String?
    
    let artwork: String?
    
    let description: String?
    
    let genre: String?
    
    let musicType: String
    
    let releaseDate: String?
    
    let title: String?
    
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
                artist: nil,
                artwork: playlist.artwork?.resized ?? playlist.artwork?.original,
                description: playlist.description,
                genre: nil,
                musicType: "playlist",
                releaseDate: nil,
                title: playlist.title,
                tracks: playlist.tracks
            )
        } else if url.query?.contains("i=") == true {
            // Apple Music song link (?i=trackID)
            let song = try await request.commands.songs.metadata(url)
            return MusicMetadataResponse(
                artist: song.artist,
                artwork: song.artwork,
                description: nil,
                genre: nil,
                musicType: "song",
                releaseDate: song.releaseDate,
                title: song.title,
                tracks: nil
            )
        } else if path.contains("/album/") {
            let album = try await request.commands.albums.metadata(url)
            return MusicMetadataResponse(
                artist: album.artist,
                artwork: album.artwork,
                description: nil,
                genre: nil,
                musicType: "album",
                releaseDate: album.releaseDate,
                title: album.title,
                tracks: album.tracks
            )
        }

        // Unknown — return minimal response; frontend shows manual type selector
        return MusicMetadataResponse(
            artist: nil,
            artwork: nil,
            description: nil,
            genre: nil,
            musicType: "unknown",
            releaseDate: nil,
            title: nil,
            tracks: nil
        )
    }
}
