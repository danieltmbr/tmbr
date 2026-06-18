import Testing
import Foundation
import SwiftData
import CoreTmbr
@testable import CoreApp

@MainActor
@Suite("PostRecord upsert")
struct PostUpsertTests {

    // Hold the container for the test's lifetime — returning a bare `mainContext` lets the container
    // deallocate out from under it (dangling context → trap).
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PostRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
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
        let container = try makeContainer()
        let context = container.mainContext
        try PostRecord.upsert([post(id: 1, title: "A"), post(id: 2, title: "B")], in: context)
        #expect(try allPosts(context).count == 2)
    }

    @Test func upsertingSameServerIDYieldsOneRecord() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try PostRecord.upsert([post(id: 1, title: "A")], in: context)
        try PostRecord.upsert([post(id: 1, title: "A")], in: context)
        let all = try allPosts(context)
        #expect(all.count == 1)
        #expect(all.first?.serverID == 1)
    }

    @Test func updatesExistingFields() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try PostRecord.upsert([post(id: 1, title: "Old", content: "old")], in: context)
        try PostRecord.upsert([post(id: 1, title: "New", content: "new")], in: context)
        let all = try allPosts(context)
        #expect(all.count == 1)
        #expect(all.first?.title == "New")
        #expect(all.first?.content == "new")
        #expect(all.first?.syncState == .synced)
    }
}
