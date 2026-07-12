import SwiftUI
import AppPersistence

struct OrphanDetailSection: View {

    let item: PreviewRecord

    @Upserter(\.orphan) private var syncer

    var body: some View {
        CataloguePreviewHeader(item: item)
            .catalogueItemRefresh(id: item.id) { [id = item.id] in
                try await syncer(id)
            }
    }
}
