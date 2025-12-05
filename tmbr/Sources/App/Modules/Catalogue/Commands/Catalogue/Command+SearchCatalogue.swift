import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct SearchCatalogueCommand: Command {
    
    typealias Input = CatalogueQueryPayload
    
    typealias Output = [Note]
    
    private let allowedTypes: Set<String> = [
        Book.previewType,
        Movie.previewType,
        Podcast.previewType,
        Song.previewType,
    ]
    
    private let queryNotes: CommandResolver<NoteQueryPayload, [Note]>
    
    init(queryNotes: CommandResolver<NoteQueryPayload, [Note]>) {
        self.queryNotes = queryNotes
    }
    
    func execute(_ payload: CatalogueQueryPayload) async throws -> [Note] {
        let input = queryInput(from: payload)
        return try await queryNotes(input)
    }
    
    private func queryInput(from payload: CatalogueQueryPayload) -> NoteQueryPayload {
        let types = filter(types: payload.types)
        return NoteQueryPayload(term: payload.term, types: types)
    }
    
    private func filter(types: Set<String>?) -> Set<String> {
        guard let types else { return allowedTypes }
        return types.filter { allowedTypes.contains($0) }
    }
}

extension CommandFactory<CatalogueQueryPayload, [Note]> {
    
    static var searchCatalogue: Self {
        CommandFactory { request in
            SearchCatalogueCommand(
                queryNotes: request.commands.notes.search
            )
            .logged(logger: request.logger)
        }
    }
}
