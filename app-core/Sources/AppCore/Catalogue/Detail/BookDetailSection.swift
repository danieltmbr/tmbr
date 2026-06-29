import SwiftUI
import SwiftData
import AppPersistence

private struct BookInfoLine: View {
    let book: BookRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [book.genre, book.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct BookDetailSection: View {

    let previewID: UUID

    @Query private var records: [BookRecord]

    @Upserter(\.book) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<BookRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let book = records.first {
            Section {
                CatalogueItemHeader(
                    title: book.title,
                    artworkURL: book.coverURL,
                    credit: book.author.isEmpty ? nil : "by \(book.author)",
                    info: { BookInfoLine(book: book) },
                    resourceURLs: book.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = book.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
        }
    }

}
