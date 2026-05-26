import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct FetchMovieMetadataCommand: Command {

    private let fetch: CommandResolver<URL, Metadata>

    private let platform: Platform<MovieMetadata>

    init(
        fetch: CommandResolver<URL, Metadata>,
        platform: Platform<MovieMetadata> = .movie
    ) {
        self.fetch = fetch
        self.platform = platform
    }

    func execute(_ url: URL) async throws -> MovieMetadata {
        guard let metadata = try await platform.metadata(for: url, fetcher: fetch.callAsFunction) else {
            throw Abort(.badRequest, reason: "Could not extract metadata from URL.")
        }
        return metadata
    }
}

extension CommandFactory<URL, MovieMetadata> {

    static var fetchMovieMetadata: Self {
        CommandFactory { request in
            FetchMovieMetadataCommand(
                fetch: request.commands.catalogue.metadata
            )
            .logged(logger: request.logger)
        }
    }
}
