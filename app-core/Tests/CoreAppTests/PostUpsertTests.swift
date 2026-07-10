import Testing
import Foundation
import SwiftData
import TmbrCore
import AppPersistence
@testable import AppCore

@MainActor
@Suite("PostStore upsert")
struct PostUpsertTests {

    // Hold the container for the test's lifetime — returning a bare `mainContext` lets the container
    // deallocate out from under it (dangling context → trap).
    private func makeStore() throws -> (PostStore, ModelContainer) {
        // PostStore.upsert reconciles embedded quotes, so QuoteRecord must be in the schema —
        // quotes are linked by `postServerID`, not an object relationship, so `for: PostRecord.self`
        // alone would omit it and trap on the QuoteRecord fetch.
        let container = try ModelContainer(
            for: PostRecord.self, QuoteRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return (PostStore(context: container.mainContext), container)
    }

    private func post(id: Int, title: String, content: String = "body") -> PostResponse {
        PostResponse(
            id: id,
            attachment: nil,
            author: UserResponse(id: 1, appleID: "apple", email: nil, firstName: nil, lastName: nil),
            content: content,
            createdAt: Date(timeIntervalSince1970: TimeInterval(id)),
            language: .en,
            publishedAt: nil,
            quotes: [],
            state: .published,
            title: title
        )
    }

    private func allPosts(_ context: ModelContext) throws -> [PostRecord] {
        try context.fetch(FetchDescriptor<PostRecord>())
    }

    @Test func insertsNewPosts() throws {
        let (store, container) = try makeStore()
        try store.upsert([post(id: 1, title: "A"), post(id: 2, title: "B")])
        #expect(try allPosts(container.mainContext).count == 2)
    }

    @Test func upsertingSameServerIDYieldsOneRecord() throws {
        let (store, container) = try makeStore()
        try store.upsert([post(id: 1, title: "A")])
        try store.upsert([post(id: 1, title: "A")])
        let all = try allPosts(container.mainContext)
        #expect(all.count == 1)
        #expect(all.first?.serverID == 1)
    }

    @Test func updatesExistingFields() throws {
        let (store, container) = try makeStore()
        try store.upsert([post(id: 1, title: "Old", content: "old")])
        try store.upsert([post(id: 1, title: "New", content: "new")])
        let all = try allPosts(container.mainContext)
        #expect(all.count == 1)
        #expect(all.first?.title == "New")
        #expect(all.first?.content == "new")
        #expect(all.first?.syncState == .synced)
    }
}
