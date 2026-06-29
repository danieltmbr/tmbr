import Testing
import Foundation
import SwiftData
import TmbrCore
import AppApi
@testable import AppCore

@MainActor
@Suite("CatalogueItemSync seams")
struct CatalogueItemSyncSeamTests {

    private let user = UserResponse(id: 1, appleID: "a", email: nil, firstName: nil, lastName: nil)

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PreviewRecord.self, SongRecord.self, NoteRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func stubSong(previewID: UUID, id: Int = 10) -> SongResponse {
        SongResponse(
            id: id, access: .public, album: nil, artist: "Artist", artwork: nil,
            genre: nil, notes: [], owner: user,
            preview: PreviewResponse(
                id: previewID, primaryInfo: "Stub", secondaryInfo: "sub", image: nil,
                resources: [], source: .init(id: id, type: "song"), category: nil,
                isNoteMatch: false, notes: nil
            ),
            post: nil, releaseDate: nil, resources: [], title: "Stub"
        )
    }

    private func count<T: PersistentModel>(_ type: T.Type, _ ctx: ModelContext) throws -> Int {
        try ctx.fetch(FetchDescriptor<T>()).count
    }

    // Network seam: a stub RequestLoader that never touches the network upserts a SongRecord.
    // Exercises \.itemLoaders injection via CatalogueItemLoaders.
    @Test func networkSeam_stubLoaderUpsertsSongRecord() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        let stub = stubSong(previewID: pid, id: 42)

        let recipe = CatalogueItemSyncs().song
        let loaders = CatalogueItemLoaders(song: { _, _ in SongItemLoader { _ in stub } })
        let upserters = CatalogueItemUpserters()
        let loader = loaders[keyPath: recipe.loaderPath](URL(string: "https://test")!, .shared)
        let upsert = upserters[keyPath: recipe.upserterPath]
        let store = CatalogueStore(context: ctx)
        let syncer = CatalogueItemSyncer<Int> { [label = recipe.label] id in
            try await Syncer(label, loader: loader, from: id) { try await upsert(store, $0) }.run()
        }

        try await syncer(42)

        #expect(try count(SongRecord.self, ctx) == 1)
        #expect(try ctx.fetch(FetchDescriptor<SongRecord>()).first?.sourceID == 42)
    }

    // Persistence seam: a spy upserter receives the response loaded via the stub loader.
    // Exercises \.itemUpserters injection via CatalogueItemUpserters.
    @Test func persistenceSeam_spyUpserterReceivesResponse() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        let stub = stubSong(previewID: pid, id: 7)

        var received: SongResponse?
        let recipe = CatalogueItemSyncs().song
        let loaders = CatalogueItemLoaders(song: { _, _ in SongItemLoader { _ in stub } })
        let upserters = CatalogueItemUpserters(song: { _, response in received = response })
        let loader = loaders[keyPath: recipe.loaderPath](URL(string: "https://test")!, .shared)
        let upsert = upserters[keyPath: recipe.upserterPath]
        let store = CatalogueStore(context: ctx)
        let syncer = CatalogueItemSyncer<Int> { [label = recipe.label] id in
            try await Syncer(label, loader: loader, from: id) { try await upsert(store, $0) }.run()
        }

        try await syncer(7)

        #expect(received?.id == 7)
    }
}
