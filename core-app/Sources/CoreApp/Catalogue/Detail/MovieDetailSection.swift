import SwiftUI
import SwiftData

private struct MovieInfoLine: View {
    let movie: MovieRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [movie.director, movie.genre, movie.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct MovieDetailSection: View {

    let previewID: UUID

    @Query private var records: [MovieRecord]

    @Upserter(\.movie) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<MovieRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let movie = records.first {
            Section {
                CatalogueItemHeader(
                    title: movie.title,
                    artworkURL: movie.coverURL,
                    info: { MovieInfoLine(movie: movie) },
                    resourceURLs: movie.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = movie.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
        }
    }

}
