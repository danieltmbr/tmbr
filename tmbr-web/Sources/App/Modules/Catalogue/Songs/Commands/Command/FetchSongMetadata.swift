import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchSongMetadataCommand: Command {

    private let fetch: CommandResolver<URL, Metadata>
    
    private let platform: Platform<SongMetadata>

    init(
        fetch: CommandResolver<URL, Metadata>,
        platform: Platform<SongMetadata> = .song
    ) {
        self.fetch = fetch
        self.platform = platform
    }

    func execute(_ url: URL) async throws -> SongMetadata {
        guard let metadata = try await platform.metadata(for: url, fetcher: fetch.callAsFunction) else {
            throw Abort(.badRequest, reason: "Could not extract metadata from URL.")
        }
        return metadata
    }
}

extension CommandFactory<URL, SongMetadata> {

    static var fetchMetadata: Self {
        CommandFactory { request in
            FetchSongMetadataCommand(
                fetch: request.commands.catalogue.metadata
            )
            .logged(logger: request.logger)
        }
    }
}
