import SwiftUI
import AppPersistence

/// A preview-backed catalogue item header, rendered entirely from a `PreviewRecord`.
/// Used as a placeholder by typed detail sections while their backing record is being
/// fetched, and as the permanent header by `OrphanDetailSection`.
struct CataloguePreviewHeader: View {

    let item: PreviewRecord

    var body: some View {
        Section {
            CatalogueItemHeader(
                title: item.primaryInfo,
                artworkURL: item.imageURL,
                info: { PreviewInfoLine(item: item) },
                resourceURLs: item.externalLinks
            )
        }
    }
}

// MARK: - Info line

struct PreviewInfoLine: View {

    let item: PreviewRecord

    var body: some View {
        let text = [item.secondaryInfo, item.categoryType.capitalized]
            .filter { !$0.isEmpty }.joined(separator: " · ")
        if !text.isEmpty {
            Text(text).foregroundStyle(.secondary)
        }
    }
}
