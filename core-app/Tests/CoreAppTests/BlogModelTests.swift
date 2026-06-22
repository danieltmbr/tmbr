import Testing
import Foundation
@testable import CoreApp

@MainActor
@Suite("BlogModel")
struct BlogModelTests {

    // MARK: - Helpers

    private func makeModel(
        refresh: @escaping @Sendable () async throws -> Date? = { nil },
        loadMore: @escaping @Sendable () async throws -> Bool = { false },
        lastFetched: Date? = nil
    ) -> BlogModel {
        BlogModel(refresh: refresh, loadMore: loadMore, lastFetched: lastFetched)
    }

    // MARK: - Initial state

    @Test func initialActiveLoadIsNil() {
        #expect(makeModel().activeLoad == nil)
    }

    @Test func initialLastFetchedIsNil() {
        #expect(makeModel().lastFetched == nil)
    }

    @Test func initialLastFetchedUsesInjectedValue() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        #expect(makeModel(lastFetched: date).lastFetched == date)
    }

    // MARK: - refresh() success

    @Test func refreshSuccessSetsLastFetchedFromClosure() async {
        let expected = Date(timeIntervalSince1970: 2_000_000)
        let model = makeModel(refresh: { expected })
        await model.refresh()
        #expect(model.lastFetched == expected)
    }

    @Test func refreshReturningNilDoesNotUpdateLastFetched() async {
        let prior = Date(timeIntervalSince1970: 1_000_000)
        let model = makeModel(refresh: { nil }, lastFetched: prior)
        await model.refresh()
        #expect(model.lastFetched == prior)
    }

    @Test func refreshSuccessClearsLastError() async {
        // Start in failed state
        let failing = makeModel(refresh: { throw LoadError.offline })
        await failing.refresh()
        guard failing.lastError != nil else {
            Issue.record("Expected lastError to be set after failed refresh")
            return
        }
        // Succeed — error must be cleared
        let model = makeModel(refresh: { Date.now })
        await model.refresh()
        #expect(model.lastError == nil)
    }

    @Test func refreshSuccessResetsHasMoreOptimistically() async {
        let model = makeModel(loadMore: { false })
        await model.refresh()
        await model.loadMore()      // settles hasMore = false
        #expect(!model.hasMore)
        await model.refresh()
        #expect(model.hasMore)
    }

    @Test func refreshActiveLoadIsNilAfterCompletion() async {
        let model = makeModel(refresh: { Date.now })
        await model.refresh()
        #expect(model.activeLoad == nil)
    }

    // MARK: - refresh() failure

    @Test func refreshFailureSetsLastError() async {
        let model = makeModel(refresh: { throw LoadError.offline })
        await model.refresh()
        #expect(model.lastError == .offline)
    }

    @Test func refreshFailurePreservesLastFetched() async {
        let prior = Date(timeIntervalSince1970: 1_000_000)
        let model = makeModel(
            refresh: { throw LoadError.offline },
            lastFetched: prior
        )
        await model.refresh()
        #expect(model.lastFetched == prior)
    }

    @Test func refreshFailureActiveLoadIsNilAfterCompletion() async {
        let model = makeModel(refresh: { throw LoadError.offline })
        await model.refresh()
        #expect(model.activeLoad == nil)
    }

    // MARK: - loadMore() happy path

    @Test func loadMoreSetsHasMoreFalseWhenNoCursorRemains() async {
        let model = makeModel(loadMore: { false })
        await model.refresh()
        #expect(model.hasMore)
        await model.loadMore()
        #expect(!model.hasMore)
    }

    @Test func loadMoreKeepsHasMoreTrueWhenCursorRemains() async {
        let model = makeModel(loadMore: { true })
        await model.refresh()
        await model.loadMore()
        #expect(model.hasMore)
    }

    @Test func isPageLoadingFalseAfterLoadMoreCompletes() async {
        let model = makeModel(loadMore: { false })
        await model.refresh()
        await model.loadMore()
        #expect(!model.isPageLoading)
    }

    // MARK: - loadMore() guards

    @Test func loadMoreBlockedWhenHasMoreIsFalse() async {
        var callCount = 0
        let model = makeModel(loadMore: {
            callCount += 1
            return false
        })
        await model.refresh()
        await model.loadMore()      // runs, sets hasMore = false
        await model.loadMore()      // blocked — hasMore == false
        #expect(callCount == 1)
    }

    @Test func loadMoreErrorIsSwallowedAndDoesNotSetLastError() async {
        let model = makeModel(
            refresh: { Date.now },
            loadMore: { throw LoadError.offline }
        )
        await model.refresh()
        await model.loadMore()
        #expect(model.lastError == nil)
    }
}
