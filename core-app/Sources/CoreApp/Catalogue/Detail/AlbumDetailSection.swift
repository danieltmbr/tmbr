import SwiftUI
import SwiftData

struct AlbumDetailSection: View {

    let previewID: UUID

    @Query private var records: [AlbumRecord]

    @Upserter(\.album) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<AlbumRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let album = records.first {
            Section {
                CatalogueItemHeader(
                    title: album.title,
                    artworkURL: album.artworkURL,
                    credit: album.artist.isEmpty ? nil : "by \(album.artist)",
                    info: infoLine(for: album),
                    resourceURLs: album.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = album.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
            if let sourceID = album.sourceID {
                TrackListSection(containerType: "album", containerSourceID: sourceID)
            }
        }
    }

    private func infoLine(for album: AlbumRecord) -> String? {
        let parts = [album.genre, album.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
