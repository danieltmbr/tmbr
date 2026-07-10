import Testing
import Foundation
@testable import AppCore

@MainActor
@Suite("FeedModel")
struct FeedModelTests {

    // MARK: - Helpers

    /// Minimal typed input standing in for PostsQuery/QuotesQuery/…
    private struct TestQuery: PageableQuery, Hashable {
        var term: String?
        var filter: String?
        var cursor: String?

        var isSearch: Bool { term != nil }

        func page(after cursor: String) -> Self {
            var query = self
            query.cursor = cursor
            return query
        }
    }

    private func makeModel(
        fetch: (@MainActor (TestQuery) async throws -> String?)? = { _ in nil }
    ) -> FeedModel<TestQuery> {
        let model = FeedModel<TestQuery>(label: "test")
        model.pipeline = fetch
        return model
    }

    // MARK: - Initial state & seeding

    @Test func initialLoadingIsNil() {
        #expect(makeModel().state.loading == nil)
    }

    @Test func initialLastFetchedIsNil() {
        #expect(makeModel().state.lastFetched == nil)
    }

    @Test func seedSetsLastFetchedWhenEmpty() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let model = makeModel()
        model.seed(lastFetched: date)
        #expect(model.state.lastFetched == date)
    }

    @Test func seedNeverOverridesAnExistingValue() async {
        let stale = Date(timeIntervalSince1970: 1_000_000)
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery())
        let live = model.state.lastFetched
        model.seed(lastFetched: stale)
        #expect(model.state.lastFetched == live)
    }

    // MARK: - No backend (fetch == nil)

    @Test func allOperationsNoOpWithoutFetch() async {
        let model = makeModel(fetch: nil)
        await model.fetch(TestQuery())
        await model.fetch(TestQuery(term: "swift"))
        await model.loadMore()
        #expect(model.state.lastFetched == nil)
        #expect(model.state.lastError == nil)
        #expect(model.state.revision == 0)
    }

    // MARK: - refresh() success

    @Test func refreshSuccessSetsLastFetched() async {
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery())
        #expect(model.state.lastFetched != nil)
    }

    @Test func refreshSuccessClearsLastError() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery())
        #expect(model.state.lastError != nil)
        model.pipeline = { _ in nil }
        await model.fetch(TestQuery())
        #expect(model.state.lastError == nil)
    }

    @Test func refreshSettlesHasMoreFromCursor() async {
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery())
        #expect(!model.state.hasMore)
        model.pipeline = { _ in "next" }
        await model.fetch(TestQuery())
        #expect(model.state.hasMore)
    }

    @Test func refreshBumpsRevision() async {
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery())
        #expect(model.state.revision == 1)
    }

    @Test func refreshLoadingIsNilAfterCompletion() async {
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery())
        #expect(model.state.loading == nil)
    }

    // MARK: - refresh() failure

    @Test func refreshFailureSetsLastError() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery())
        #expect(model.state.lastError == .offline)
    }

    @Test func refreshFailurePreservesLastFetched() async {
        let prior = Date(timeIntervalSince1970: 1_000_000)
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        model.seed(lastFetched: prior)
        await model.fetch(TestQuery())
        #expect(model.state.lastFetched == prior)
    }

    @Test func refreshFailurePreservesActiveSession() async {
        // A failed refresh must not clobber the previous session — load-more can continue it.
        var received: TestQuery?
        let model = makeModel(fetch: { query in
            received = query
            return query.cursor == nil ? "page-2" : nil
        })
        await model.fetch(TestQuery(filter: "en"))
        model.pipeline = { _ in throw LoadError.offline }
        await model.fetch(TestQuery(filter: "hu"))
        model.pipeline = { query in
            received = query
            return nil
        }
        await model.loadMore()
        #expect(received?.cursor == "page-2")
        #expect(received?.filter == "en")
    }

    @Test func refreshFailureDoesNotBumpRevision() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery())
        #expect(model.state.revision == 0)
    }

    @Test func refreshFailureLoadingIsNilAfterCompletion() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery())
        #expect(model.state.loading == nil)
    }

    // MARK: - search()

    @Test func searchPassesInputVerbatim() async {
        var received: TestQuery?
        let model = makeModel(fetch: { query in
            received = query
            return nil
        })
        await model.fetch(TestQuery(term: "swift", filter: "en"))
        #expect(received?.term == "swift")
        #expect(received?.filter == "en")
        #expect(received?.cursor == nil)
    }

    @Test func searchFailureSetsLastErrorAndStopsPaging() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery(term: "swift"))
        #expect(model.state.lastError == .offline)
        #expect(!model.state.hasMore)
    }

    @Test func searchBumpsRevision() async {
        let model = makeModel(fetch: { _ in nil })
        await model.fetch(TestQuery(term: "swift"))
        #expect(model.state.revision == 1)
    }

    // MARK: - loadMore() session threading

    @Test func loadMoreThreadsCursorIntoSessionInput() async {
        var received: TestQuery?
        let model = makeModel(fetch: { query in
            received = query
            return query.cursor == nil ? "page-2" : nil
        })
        await model.fetch(TestQuery(term: "swift", filter: "hu"))
        await model.loadMore()
        #expect(received?.term == "swift")
        #expect(received?.filter == "hu")
        #expect(received?.cursor == "page-2")
    }

    @Test func refreshAfterSearchStartsANewSession() async {
        var received: TestQuery?
        let model = makeModel(fetch: { query in
            received = query
            return "next"
        })
        await model.fetch(TestQuery(term: "swift"))
        await model.fetch(TestQuery())
        await model.loadMore()
        #expect(received?.term == nil)
        #expect(received?.cursor == "next")
    }

    // MARK: - loadMore() outcomes

    @Test func loadMoreSetsHasMoreFalseWhenNoCursorRemains() async {
        let model = makeModel(fetch: { query in query.cursor == nil ? "page-2" : nil })
        await model.fetch(TestQuery())
        #expect(model.state.hasMore)
        await model.loadMore()
        #expect(!model.state.hasMore)
    }

    @Test func loadMoreKeepsHasMoreTrueWhenCursorRemains() async {
        let model = makeModel(fetch: { _ in "next" })
        await model.fetch(TestQuery())
        await model.loadMore()
        #expect(model.state.hasMore)
    }

    @Test func loadMoreBumpsRevision() async {
        let model = makeModel(fetch: { _ in "next" })
        await model.fetch(TestQuery())
        await model.loadMore()
        #expect(model.state.revision == 2)
    }

    @Test func loadingIsNilAfterLoadMoreCompletes() async {
        let model = makeModel(fetch: { _ in "next" })
        await model.fetch(TestQuery())
        await model.loadMore()
        #expect(model.state.loading == nil)
    }

    // MARK: - loadMore() guards

    @Test func loadMoreWithoutPriorFetchIsNoOp() async {
        var callCount = 0
        let model = makeModel(fetch: { @MainActor _ in
            callCount += 1
            return nil
        })
        await model.loadMore()      // no session yet — cold start
        #expect(callCount == 0)
    }

    @Test func loadMoreBlockedWhenHasMoreIsFalse() async {
        var callCount = 0
        let model = makeModel(fetch: { @MainActor query in
            callCount += 1
            return query.cursor == nil ? "page-2" : nil
        })
        await model.fetch(TestQuery())
        await model.loadMore()      // runs, returns nil cursor → hasMore = false
        await model.loadMore()      // blocked
        #expect(callCount == 2)
    }

    @Test func loadMoreErrorIsSwallowedAndDoesNotSetLastError() async {
        let model = makeModel(fetch: { query in
            if query.cursor == nil { return "page-2" }
            throw LoadError.offline
        })
        await model.fetch(TestQuery())
        await model.loadMore()
        #expect(model.state.lastError == nil)
        #expect(model.state.hasMore)      // untouched — user can retry
    }

    // MARK: - Cursored inputs (continuations by shape)

    @Test func cursoredInputIsAQuietContinuation() async {
        // A cursor in the input marks a continuation regardless of who built it:
        // failures stay silent and the retryable page-1 input is not redefined.
        let model = makeModel(fetch: { query in
            if query.cursor != nil { throw LoadError.offline }
            return "page-2"
        })
        await model.fetch(TestQuery(filter: "en"))
        await model.fetch(TestQuery(filter: "en", cursor: "page-2"))
        #expect(model.state.lastError == nil)
        #expect(model.state.loading == nil)

        var received: TestQuery?
        model.pipeline = { query in
            received = query
            return nil
        }
        await model.retry()
        #expect(received?.cursor == nil)    // retry re-fires page 1, not the failed page
    }

    // MARK: - Session mode

    @Test func sessionModeTracksLastRequest() async {
        let model = makeModel(fetch: { _ in nil })
        #expect(!model.state.isSearching)
        await model.fetch(TestQuery(term: "swift"))
        #expect(model.state.isSearching)
        await model.fetch(TestQuery())
        #expect(!model.state.isSearching)
    }

    // MARK: - Superseding (page-1 requests fire immediately, last writer wins)

    @Test func newSearchSupersedesInFlightRequest() async {
        let model = makeModel()
        model.pipeline = { [state = model.state] query in
            if query.term == "old" {
                // Worst-case interleaving: suspend until superseded, then keep suspending
                // until the winner has committed, and only then exit the way a cancelled
                // URLSession does — the loser resumes *after* the winner.
                while !Task.isCancelled { await Task.yield() }
                while state.revision == 0 { await Task.yield() }
                throw CancellationError()
            }
            return "new-cursor"
        }

        let first = Task { await model.fetch(TestQuery(term: "old")) }
        while model.state.loading == nil { await Task.yield() }    // "old" is now in flight
        let winner = await model.fetch(TestQuery(term: "new"))
        #expect(winner?.nextCursor == "new-cursor")

        // The superseded request converges on the winner's receipt — a late resumption can
        // never hand the view a stale nil — and surfaced nothing.
        let superseded = await first.value
        #expect(superseded == winner)
        #expect(model.state.lastError == nil)
        #expect(model.state.loading == nil)
        #expect(model.state.hasMore)

        // …and the session belongs to "new": load-more continues it.
        var received: TestQuery?
        model.pipeline = { query in
            received = query
            return nil
        }
        await model.loadMore()
        #expect(received?.term == "new")
        #expect(received?.cursor == "new-cursor")
    }

    // MARK: - Fetch receipts (the view's paging state)

    @Test func committedFetchReturnsReceipt() async {
        let frontier = Date(timeIntervalSince1970: 1_760_000_000)
        let model = makeModel(fetch: { _ in frontier.formatted(.iso8601) })
        let page = await model.fetch(TestQuery())
        #expect(page?.nextCursor == frontier.formatted(.iso8601))
        #expect(page?.frontier == frontier)
    }

    @Test func exhaustedFetchReturnsReceiptWithoutCursor() async {
        let model = makeModel(fetch: { _ in nil })
        let page = await model.fetch(TestQuery())
        #expect(page != nil)
        #expect(page?.nextCursor == nil)
    }

    @Test func failedFetchReturnsNoReceipt() async {
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        let page = await model.fetch(TestQuery())
        #expect(page == nil)
    }

    // MARK: - retry()

    @Test func retryReRunsLastSearch() async {
        var received: TestQuery?
        let model = makeModel(fetch: { query in
            received = query
            return nil
        })
        await model.fetch(TestQuery(term: "swift", filter: "en"))
        received = nil
        await model.retry()
        #expect(received?.term == "swift")
        #expect(received?.filter == "en")
    }

    @Test func retryReRunsAFailedFirstRefresh() async {
        // The attempted request is remembered even when it fails, so the empty view's
        // "Try Again" works after a cold-start failure.
        let model = makeModel(fetch: { _ in throw LoadError.offline })
        await model.fetch(TestQuery(filter: "en"))
        #expect(model.state.lastError == .offline)

        var received: TestQuery?
        model.pipeline = { query in
            received = query
            return nil
        }
        await model.retry()
        #expect(received?.filter == "en")
        #expect(model.state.lastError == nil)
        #expect(model.state.lastFetched != nil)     // retried refresh records freshness
    }

    @Test func retryBeforeAnyRequestIsNoOp() async {
        var callCount = 0
        let model = makeModel(fetch: { @MainActor _ in
            callCount += 1
            return nil
        })
        await model.retry()
        #expect(callCount == 0)
    }

    // MARK: - Input-less sync feed sugar

    @Test func syncFeedFetches() async {
        var callCount = 0
        let model = FeedModel<CatalogueSyncQuery>(label: "catalogue")
        model.pipeline = { @MainActor _ in
            callCount += 1
            return nil
        }
        await model.fetch()
        #expect(callCount == 1)
        #expect(!model.state.hasMore)     // nil cursor → loadMore never fires
    }
}
