import SwiftUI

extension View {
    func catalogue(_ model: CatalogueModel) -> some View {
        environment(model)
            .environment(\.syncCatalogue, SyncCatalogueAction(model: model))
    }
}
