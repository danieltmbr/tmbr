import Testing
import Foundation
import SwiftData
import TmbrCore
import AppApi
import AppPersistence
@testable import AppCore

@MainActor
@Suite("Feed seams")
struct FeedSeamTests {

    /// `RequestLoader` closures are `@Sendable`; spying on their input needs a main-actor box.
    @MainActor
    private final class Box<Value> {
        var value: Value?
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PostRecord.self, QuoteRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func stubPost(id: Int) -> PostResponse {
        PostResponse(
            id: id,
            attachment: nil,
            author: UserResponse(id: 1, appleID: "a", email: nil, firstName: nil, lastName: nil),
            content: "body",
            createdAt: Date(timeIntervalSince1970: TimeInterval(id)),
            language: .en,
            publishedAt: nil,
            quotes: [],
            state: .published,
            title: "Stub"
        )
    }

    /// Builds a model wired the way the `.feed(_:)` modifier does — identity, paging, and the
    /// fetch pipeline all from the configuration — so the seams are exercised without SwiftUI.
    private func makeModel(
        _ configuration: FeedConfiguration<PostsQuery>,
        context: ModelContext
    ) -> FeedModel<PostsQuery> {
        let model = FeedModel<PostsQuery>(label: configuration.label)
        model.pipeline = configuration.makeFetch(URL(string: "https://test")!, .shared, context)
        return model
    }

    // Network seam: an injected configuration with a stub loader never touches the network and
    // upserts PostRecords through the real store.
    @Test func networkSeam_stubLoaderUpsertsPostRecords() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let page = PageResult(items: [stubPost(id: 1), stubPost(id: 2)], nextCursor: "more")

        let configuration = FeedConfiguration<PostsQuery>(
            label: "posts",
            loader: { _, _ in PostsLoader { _ in page } },
            upsert: { try PostStore(context: $0).upsert($1.items) },
            nextCursor: { $0.nextCursor }
        )
        let model = makeModel(configuration, context: ctx)

        await model.fetch(PostsQuery())

        #expect(try ctx.fetch(FetchDescriptor<PostRecord>()).count == 2)
        #expect(model.state.hasMore)
        #expect(model.state.lastError == nil)
    }

    // Persistence seam: a spy upserter receives the response loaded via the stub loader, and the
    // typed input (term, filters) reaches the loader verbatim; load-more threads the cursor via
    // the descriptor's nextInput while preserving the other fields.
    @Test func persistenceSeam_spyUpserterReceivesResponse() async throws {
        let container = try makeContainer()
        let ctx = container.mainContext

        let sentQuery = Box<PostsQuery>()
        var received: PageResult<PostResponse>?
        let configuration = FeedConfiguration<PostsQuery>(
            label: "posts",
            loader: { _, _ in
                PostsLoader { query in
                    await MainActor.run { sentQuery.value = query }
                    return PageResult(items: [], nextCursor: query.cursor == nil ? "page-2" : nil)
                }
            },
            upsert: { _, response in received = response },
            nextCursor: { $0.nextCursor }
        )
        let model = makeModel(configuration, context: ctx)

        await model.fetch(PostsQuery(languages: ["en"], term: "swift"))
        #expect(sentQuery.value?.term == "swift")
        #expect(sentQuery.value?.cursor == nil)
        #expect(sentQuery.value?.languages == ["en"])
        #expect(received != nil)

        await model.loadMore()
        #expect(sentQuery.value?.cursor == "page-2")
        #expect(sentQuery.value?.term == "swift")           // session preserved through paging
        #expect(sentQuery.value?.languages == ["en"])

        #expect(try ctx.fetch(FetchDescriptor<PostRecord>()).isEmpty)  // spy replaced the real upsert
    }

    // The mapping helpers the tab views use to translate filter selections into API parameters.
    @Test func filterSetsMapToAPIParameterValues() {
        #expect(Set<Language>().apiValues == nil)
        #expect(Set<Language>([.en, .hu]).apiValues == ["en", "hu"])
        #expect(Set<QuoteSourceFilter>().apiValues == nil)
        #expect(Set<QuoteSourceFilter>([.blogPosts]).apiValues == ["blog_posts"])
        #expect(Set<CatalogueCategory>().apiValues == nil)
    }
}
