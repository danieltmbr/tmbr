import Testing
import Foundation
import SwiftData
import TmbrCore
@testable import AppCore

@MainActor
@Suite("Catalogue upsert")
struct CatalogueUpsertTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PreviewRecord.self, SongRecord.self, NoteRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private let user = UserResponse(id: 1, appleID: "a", email: nil, firstName: nil, lastName: nil)

    private func preview(_ id: UUID, type: String = "song", sourceID: Int? = 10, category: String? = nil, title: String = "Title", notes: [NoteResponse]? = nil) -> PreviewResponse {
        PreviewResponse(
            id: id, primaryInfo: title, secondaryInfo: "sub", image: nil, resources: [],
            source: .init(id: sourceID, type: type), category: category, isNoteMatch: false, notes: notes
        )
    }

    private func note(_ id: UUID, on attachment: PreviewResponse, body: String = "note") -> NoteResponse {
        NoteResponse(id: id, access: .public, attachment: attachment, author: user, body: body, created: Date(timeIntervalSince1970: 1), language: .en, quotes: [])
    }

    private func song(previewID: UUID, id: Int = 10, title: String = "Song", notes: [NoteResponse] = []) -> SongResponse {
        SongResponse(id: id, access: .public, album: nil, artist: "Artist", artwork: nil, genre: nil, notes: notes, owner: user, preview: preview(previewID, sourceID: id, title: title), post: nil, releaseDate: nil, resources: [], title: title)
    }

    private func count<T: PersistentModel>(_ type: T.Type, _ ctx: ModelContext) throws -> Int {
        try ctx.fetch(FetchDescriptor<T>()).count
    }

    @Test func upsertCreatesPreviewTypedAndNotes() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        let noteID = UUID()
        let s = song(previewID: pid, title: "Glow")
        let withNote = SongResponse(id: s.id, access: s.access, album: s.album, artist: s.artist, artwork: s.artwork, genre: s.genre, notes: [note(noteID, on: s.preview)], owner: user, preview: s.preview, post: nil, releaseDate: nil, resources: s.resources, title: s.title)
        try CatalogueStore(context: ctx).upsert([withNote])

        #expect(try count(PreviewRecord.self, ctx) == 1)
        #expect(try count(SongRecord.self, ctx) == 1)
        #expect(try count(NoteRecord.self, ctx) == 1)
        let preview = try ctx.fetch(FetchDescriptor<PreviewRecord>()).first
        #expect(preview?.id == pid)
        #expect(preview?.primaryInfo == "Glow")
        #expect(preview?.categoryType == "song")
        let noteRecord = try ctx.fetch(FetchDescriptor<NoteRecord>()).first
        #expect(noteRecord?.attachmentPreviewID == pid)
        #expect(noteRecord?.serverID == noteID)
    }

    @Test func reupsertDeduplicates() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        try CatalogueStore(context: ctx).upsert([song(previewID: pid, title: "A")])
        try CatalogueStore(context: ctx).upsert([song(previewID: pid, title: "B")])
        #expect(try count(PreviewRecord.self, ctx) == 1)
        #expect(try count(SongRecord.self, ctx) == 1)
        #expect(try ctx.fetch(FetchDescriptor<SongRecord>()).first?.title == "B")
    }

    @Test func reconcileRemovesServerDeletedNote() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        let a = UUID(), b = UUID()
        let p = preview(pid)
        try CatalogueStore(context: ctx).upsert([song(previewID: pid, notes: [note(a, on: p), note(b, on: p)])])
        #expect(try count(NoteRecord.self, ctx) == 2)
        // re-fetch with only note A → B is dropped
        try CatalogueStore(context: ctx).upsert([song(previewID: pid, notes: [note(a, on: p)])])
        let notes = try ctx.fetch(FetchDescriptor<NoteRecord>())
        #expect(notes.count == 1)
        #expect(notes.first?.serverID == a)
    }

    @Test func orphanUpsert() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let pid = UUID()
        let orphan = preview(pid, type: "recipe", sourceID: nil, category: "Recipe", title: "Risotto", notes: [note(UUID(), on: preview(pid, sourceID: nil))])
        try CatalogueStore(context: ctx).upsertOrphans([orphan])
        let preview = try ctx.fetch(FetchDescriptor<PreviewRecord>()).first
        #expect(preview?.isOrphan == true)
        #expect(preview?.categoryType == "Recipe")
        #expect(try count(NoteRecord.self, ctx) == 1)
    }
}
