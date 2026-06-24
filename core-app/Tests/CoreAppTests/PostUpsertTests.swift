import Testing
import Foundation
import SwiftData
import CoreTmbr
@testable import CoreApp

@MainActor
@Suite("PostStore upsert")
struct PostUpsertTests {

    // Hold the container for the test's lifetime — returning a bare `mainContext` lets the container
    // deallocate out from under it (dangling context → trap).
    private func makeStore() throws -> (PostStore, ModelContext) {
        let container = try ModelContainer(
            for: PostRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return (PostStore(context: container.mainContext), container.mainContext)
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
            state: .published,
            title: title
        )
    }

    private func allPosts(_ context: ModelContext) throws -> [PostRecord] {
        try context.fetch(FetchDescriptor<PostRecord>())
    }

    @Test func insertsNewPosts() throws {
        let (store, context) = try makeStore()
        try store.upsert([post(id: 1, title: "A"), post(id: 2, title: "B")])
        #expect(try allPosts(context).count == 2)
    }

    @Test func upsertingSameServerIDYieldsOneRecord() throws {
        let (store, context) = try makeStore()
        try store.upsert([post(id: 1, title: "A")])
        try store.upsert([post(id: 1, title: "A")])
        let all = try allPosts(context)
        #expect(all.count == 1)
        #expect(all.first?.serverID == 1)
    }

    @Test func updatesExistingFields() throws {
        let (store, context) = try makeStore()
        try store.upsert([post(id: 1, title: "Old", content: "old")])
        try store.upsert([post(id: 1, title: "New", content: "new")])
        let all = try allPosts(context)
        #expect(all.count == 1)
        #expect(all.first?.title == "New")
        #expect(all.first?.content == "new")
        #expect(all.first?.syncState == .synced)
    }
}
