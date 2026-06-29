import Foundation
import Vapor
import WebCore

struct FetchPlaylistMetadataCommand: Command {

    private let fetch: CommandResolver<URL, Metadata>

    private let platform: Platform<PlaylistMetadata>

    init(
        fetch: CommandResolver<URL, Metadata>,
        platform: Platform<PlaylistMetadata> = .playlist
    ) {
        self.fetch = fetch
        self.platform = platform
    }

    func execute(_ url: URL) async throws -> PlaylistMetadata {
        guard let metadata = try await platform.metadata(for: url, fetcher: fetch.callAsFunction) else {
            throw Abort(.badRequest, reason: "Could not extract metadata from URL.")
        }
        return metadata
    }
}

extension CommandFactory<URL, PlaylistMetadata> {

    static var fetchPlaylistMetadata: Self {
        CommandFactory { request in
            FetchPlaylistMetadataCommand(
                fetch: request.commands.catalogue.metadata
            )
            .logged(logger: request.logger)
        }
    }
}
