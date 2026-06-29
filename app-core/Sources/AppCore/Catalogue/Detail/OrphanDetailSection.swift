import SwiftUI
import AppPersistence

private struct OrphanInfoLine: View {
    let item: PreviewRecord

    var body: some View {
        let text = [item.secondaryInfo, item.categoryType.capitalized]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
        if !text.isEmpty {
            Text(text).foregroundStyle(.secondary)
        }
    }
}

struct OrphanDetailSection: View {

    let item: PreviewRecord

    @Upserter(\.orphan) private var syncer

    var body: some View {
        Section {
            CatalogueItemHeader(
                title: item.primaryInfo,
                artworkURL: item.imageURL,
                info: { OrphanInfoLine(item: item) },
                resourceURLs: item.externalLinks
            )
        }
        .catalogueItemRefresh(id: item.id) { [id = item.id] in
            try await syncer(id)
        }
    }
}
