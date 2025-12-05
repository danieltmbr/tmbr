import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct ListCatalogueCommand: Command {
    
    typealias Input = CatalogueQueryPayload
    
    typealias Output = [Preview]
    
    private let allowedTypes: Set<String> = [
        Book.previewType,
        Movie.previewType,
        Podcast.previewType,
        Song.previewType,
    ]
    
    private let queryPreviews: CommandResolver<PreviewQueryInput, [Preview]>
    
    init(queryPreviews: CommandResolver<PreviewQueryInput, [Preview]>) {
        self.queryPreviews = queryPreviews
    }
    
    func execute(_ payload: CatalogueQueryPayload) async throws -> [Preview] {
        let input = queryInput(from: payload)
        return try await queryPreviews(input)
    }
    
    private func queryInput(from payload: CatalogueQueryPayload) -> PreviewQueryInput {
        let types = filter(types: payload.types)
        return PreviewQueryInput(types: types)
    }
    
    private func filter(types: Set<String>?) -> Set<String> {
        guard let types else { return allowedTypes }
        return types.filter { allowedTypes.contains($0) }
    }
}

extension CommandFactory<CatalogueQueryPayload, [Preview]> {
    
    static var listCatalogue: Self {
        CommandFactory { request in
            ListCatalogueCommand(
                queryPreviews: request.commands.previews.list
            )
            .logged(logger: request.logger)
        }
    }
}
