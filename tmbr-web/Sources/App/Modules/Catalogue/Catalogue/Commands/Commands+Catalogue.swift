import Foundation
import WebCore

extension Commands {
    var catalogue: Commands.Catalogue.Type { Commands.Catalogue.self }
}

extension Commands {
    
    struct Catalogue: CommandCollection, Sendable {

        let metadata: CommandFactory<URL, Metadata>

        let search: CommandFactory<CatalogueQueryPayload, CatalogueSearchResult>

        init(
            metadata: CommandFactory<URL, Metadata> = .fetchMetadata,
            search: CommandFactory<CatalogueQueryPayload, CatalogueSearchResult> = .searchCatalogue
        ) {
            self.metadata = metadata
            self.search = search
        }
    }
}
