import SwiftUI
import SwiftData
import AppPersistence

private struct SongInfoLine: View {
    let song: SongRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [song.album, song.genre, song.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct SongDetailSection: View {

    let previewID: UUID

    @Query private var records: [SongRecord]

    @Upserter(\.song) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<SongRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let song = records.first {
            Section {
                CatalogueItemHeader(
                    title: song.title,
                    artworkURL: song.artworkURL,
                    credit: song.artist.isEmpty ? nil : "by \(song.artist)",
                    info: { SongInfoLine(song: song) },
                    resourceURLs: song.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = song.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
        }
    }

}
