import Foundation
import Vapor
import Core
import AuthKit

struct PromoteSongCommand: Command {

    private let fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>

    private let fetchContainerEntry: CommandResolver<ContainerEntryInput, ContainerEntry>

    private let fetchAlbum: CommandResolver<FetchParameters<AlbumID>, Album>

    private let create: CommandResolver<SongInput, Song>

    init(
        fetchPreview: CommandResolver<FetchParameters<PreviewID>, Preview>,
        fetchContainerEntry: CommandResolver<ContainerEntryInput, ContainerEntry>,
        fetchAlbum: CommandResolver<FetchParameters<AlbumID>, Album>,
        create: CommandResolver<SongInput, Song>
    ) {
        self.fetchPreview = fetchPreview
        self.fetchContainerEntry = fetchContainerEntry
        self.fetchAlbum = fetchAlbum
        self.create = create
    }

    func execute(_ previewID: UUID) async throws -> Song {
        let preview = try await fetchPreview(previewID, for: .read)
        let entry = try await fetchContainerEntry(ContainerEntryInput(previewID: previewID, containerType: "album"))
        let album = try await fetchAlbum(entry.containerID, for: .read)
        return try await create(SongInput(
            previewID: previewID,
            access: preview.parentAccess,
            album: album.title,
            artist: album.artist,
            artwork: album.$artwork.id,
            genre: album.genre,
            releaseDate: nil,
            resourceURLs: preview.externalLinks,
            title: preview.primaryInfo
        ))
    }
}

extension CommandFactory<UUID, Song> {
    static var promoteSong: Self {
        CommandFactory { request in
            PromoteSongCommand(
                fetchPreview: request.commands.previews.fetch,
                fetchContainerEntry: request.commands.previews.fetchContainerEntry,
                fetchAlbum: request.commands.albums.fetch,
                create: request.commands.songs.create
            )
            .logged(name: "Promote Song", logger: request.logger)
        }
    }
}
