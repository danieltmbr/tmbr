import SwiftUI
import SwiftData

/// Renders the ordered track list for an album or playlist from cached `ContainerEntryRecord`s.
/// Pass `containerType` ("album" | "playlist") and the container's backing `sourceID` (Int).
struct TrackListSection: View {

    @Query private var entries: [ContainerEntryRecord]

    init(containerType: String, containerSourceID: Int) {
        _entries = Query(
            filter: #Predicate<ContainerEntryRecord> {
                $0.containerType == containerType && $0.containerSourceID == containerSourceID
            },
            sort: \.position
        )
    }

    var body: some View {
        if !entries.isEmpty {
            Section("Tracks") {
                ForEach(entries, id: \.clientKey) { entry in
                    if entry.href != nil {
                        NavigationLink(value: CatalogueItemNavigation(previewID: entry.memberPreviewID)) {
                            trackLabel(for: entry)
                        }
                    } else {
                        trackLabel(for: entry)
                    }
                }
            }
        }
    }

    private func trackLabel(for entry: ContainerEntryRecord) -> some View {
        HStack {
            Text("\(entry.position)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 24, alignment: .trailing)
            Text(entry.title)
        }
    }
}
