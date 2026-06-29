import SwiftUI
import SwiftData

/// Lightweight navigation value for pushing a catalogue item detail without storing a live
/// SwiftData model in the path. Storing `@Model` references in `NavigationPath` causes stale
/// reference failures after syncs; a plain UUID is stable across model context updates.
struct CatalogueItemNavigation: Hashable {
    let previewID: UUID
}

extension CatalogueItemNavigation {
    /// Fetches the `PreviewRecord` from SwiftData and presents its detail view.
    /// Falls back to an empty view if the record has been evicted (edge case).
    @MainActor
    static func destination(_ nav: CatalogueItemNavigation) -> some View {
        CatalogueItemNavigationDestination(previewID: nav.previewID)
    }
}

private struct CatalogueItemNavigationDestination: View {

    let previewID: UUID

    @Query private var records: [PreviewRecord]

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<PreviewRecord> { $0.id == previewID })
    }

    var body: some View {
        if let item = records.first {
            CatalogueItemDetailView(item: item)
        }
    }
}
