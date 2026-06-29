import SwiftUI

struct OrphanDetailSection: View {

    let item: PreviewRecord

    @Upserter(\.orphan) private var syncer

    var body: some View {
        Section {
            CatalogueItemHeader(
                title: item.primaryInfo,
                artworkURL: item.imageURL,
                info: [item.secondaryInfo, item.categoryType.capitalized]
                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                resourceURLs: item.externalLinks
            )
        }
        .catalogueItemRefresh(id: item.id) { [id = item.id] in
            try await syncer(id)
        }
    }
}
