import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchAlbumMetadataCommand: Command {

    private let fetch: CommandResolver<URL, Metadata>

    private let platform: Platform<AlbumMetadata>

    init(
        fetch: CommandResolver<URL, Metadata>,
        platform: Platform<AlbumMetadata> = .album
    ) {
        self.fetch = fetch
        self.platform = platform
    }

    func execute(_ url: URL) async throws -> AlbumMetadata {
        guard let metadata = try await platform.metadata(for: url, fetcher: fetch.callAsFunction) else {
            throw Abort(.badRequest, reason: "Could not extract metadata from URL.")
        }
        return metadata
    }
}

extension CommandFactory<URL, AlbumMetadata> {

    static var fetchMetadata: Self {
        CommandFactory { request in
            FetchAlbumMetadataCommand(
                fetch: request.commands.catalogue.metadata
            )
            .logged(logger: request.logger)
        }
    }
}
