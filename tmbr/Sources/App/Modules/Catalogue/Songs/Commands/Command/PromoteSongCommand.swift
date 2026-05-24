import Foundation
import Vapor
import Core
import AuthKit

struct PromoteSongCommand: Command {

    private let fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>

    private let fetchContainerEntry: CommandResolver<ContainerEntryInput, ContainerEntry>

    private let fetchAlbum: CommandResolver<FetchParameters<AlbumID>, Album>

    private let fetchSongMetadata: CommandResolver<URL, SongMetadata>

    private let galleryLookup: CommandResolver<String, Image?>

    private let galleryAddFromURL: CommandResolver<ImageURLPayload, Image>

    private let create: CommandResolver<SongInput, Song>

    init(
        fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>,
        fetchContainerEntry: CommandResolver<ContainerEntryInput, ContainerEntry>,
        fetchAlbum: CommandResolver<FetchParameters<AlbumID>, Album>,
        fetchSongMetadata: CommandResolver<URL, SongMetadata>,
        galleryLookup: CommandResolver<String, Image?>,
        galleryAddFromURL: CommandResolver<ImageURLPayload, Image>,
        create: CommandResolver<SongInput, Song>
    ) {
        self.fetchPreview = fetchPreview
        self.fetchContainerEntry = fetchContainerEntry
        self.fetchAlbum = fetchAlbum
        self.fetchSongMetadata = fetchSongMetadata
        self.galleryLookup = galleryLookup
        self.galleryAddFromURL = galleryAddFromURL
        self.create = create
    }

    func execute(_ previewID: UUID) async throws -> Song {
        let preview = try await fetchPreview(previewID, for: .read)
        let entry = try await fetchContainerEntry(ContainerEntryInput(previewID: previewID))

        if entry.containerType == "album" {
            let album = try await fetchAlbum(entry.containerID, for: .read)
            return try await create(SongInput(
                previewID: previewID,
                access: preview.parentAccess,
                album: album.title,
                artist: album.artist,
                artwork: album.$artwork.id,
                genre: album.genre,
                releaseDate: album.releaseDate,
                resourceURLs: preview.externalLinks,
                title: preview.primaryInfo
            ))
        } else {
            let songMeta = await fetchMetadataFromURL(preview.externalLinks.first)
            let artworkID = await resolveArtwork(songMeta?.artwork, title: preview.primaryInfo)
            return try await create(SongInput(
                previewID: previewID,
                access: preview.parentAccess,
                album: songMeta?.album,
                artist: songMeta?.artist ?? "",
                artwork: artworkID,
                genre: songMeta?.genre,
                releaseDate: songMeta?.releaseDate.flatMap(Self.parseDate),
                resourceURLs: preview.externalLinks,
                title: preview.primaryInfo
            ))
        }
    }

    private func fetchMetadataFromURL(_ urlString: String?) async -> SongMetadata? {
        guard let urlString, let url = URL(string: urlString) else { return nil }
        return try? await fetchSongMetadata(url)
    }

    private func resolveArtwork(_ urlString: String?, title: String) async -> ImageID? {
        guard let urlString else { return nil }
        if let existing = try? await galleryLookup(urlString) {
            return try? existing.requireID()
        }
        return try? await galleryAddFromURL(ImageURLPayload(url: urlString, alt: title)).requireID()
    }

    private static func parseDate(from string: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: string) { return date }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: string)
    }
}

extension CommandFactory<UUID, Song> {
    static var promoteSong: Self {
        CommandFactory { request in
            PromoteSongCommand(
                fetchPreview: request.commands.previews.fetch,
                fetchContainerEntry: request.commands.previews.fetchContainerEntry,
                fetchAlbum: request.commands.albums.fetch,
                fetchSongMetadata: request.commands.songs.metadata,
                galleryLookup: request.commands.gallery.lookup,
                galleryAddFromURL: request.commands.gallery.addFromURL,
                create: request.commands.songs.promoteCreate
            )
            .logged(name: "Promote Song", logger: request.logger)
        }
    }
}
