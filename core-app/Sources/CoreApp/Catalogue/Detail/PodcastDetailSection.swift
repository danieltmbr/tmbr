import SwiftUI
import SwiftData

private struct PodcastInfoLine: View {
    let podcast: PodcastRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [seasonEpisode, podcast.genre, podcast.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var seasonEpisode: String? {
        if let s = podcast.seasonNumber, let e = podcast.episodeNumber { return "S\(s):E\(e)" }
        if let e = podcast.episodeNumber { return "E\(e)" }
        return nil
    }
}

struct PodcastDetailSection: View {

    let previewID: UUID

    @Query private var records: [PodcastRecord]

    @Upserter(\.podcast) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<PodcastRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let podcast = records.first {
            Section {
                CatalogueItemHeader(
                    title: podcast.title,
                    artworkURL: podcast.artworkURL,
                    credit: podcast.episodeTitle.isEmpty ? nil : podcast.episodeTitle,
                    info: { PodcastInfoLine(podcast: podcast) },
                    resourceURLs: podcast.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = podcast.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
        }
    }

}
