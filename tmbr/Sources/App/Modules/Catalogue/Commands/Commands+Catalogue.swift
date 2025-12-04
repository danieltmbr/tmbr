import Foundation
import Core

extension Commands {
    var catalogue: Commands.Catalogue.Type { Commands.Catalogue.self }
}

extension Commands {
    struct Catalogue: CommandCollection, Sendable {
                
        let list: CommandFactory<CatalogueQueryPayload, [Preview]>
        
        let search: CommandFactory<CatalogueQueryPayload, [Note]>
        
        init(
            list: CommandFactory<CatalogueQueryPayload, [Preview]> = .listCatalogue,
            search: CommandFactory<CatalogueQueryPayload, [Note]> = .searchCatalogue,
        ) {
            self.list = list
            self.search = search
        }
    }
}
