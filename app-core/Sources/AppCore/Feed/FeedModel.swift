import Foundation
import OSLog

/// The receipt of a committed fetch — everything the owning view needs to page further.
/// `nil` in `FeedModel.fetch`'s return means the request did **not** commit (failed or
/// superseded): keep your previous paging state so the same page can be retried.
public struct FeedPage: Hashable, Sendable {

    /// Cursor for the next page; `nil` = the feed has no more pages.
    public let nextCursor: String?

    /// The fetched frontier — the cursor as a date. Rows older than this are unverified local
    /// cache; displaying one is the signal to fetch the next page. `nil` when the cursor
    /// doesn't parse (the paging convenience still works via `loadMore()`).
    public let frontier: Date?
}

/// Headless network behavior for one server-backed feed; the list renders from the local store,
/// this model fetches + upserts (inside the pipeline) and publishes progress through `state`.
///
/// **The view is in control**: it constructs the endpoint's own `Input` and calls `fetch(_:)` —
/// the input alone decides what happens, read through its `PageableQuery` conformance. A
/// committed fetch returns a `FeedPage` receipt; the view stores it as its paging state, the
/// source of truth.
///
/// The model keeps convenience copies of the session **only** for the self-contained controls,
/// which can't construct an `Input`: `loadMore()` (`FeedLoadMoreCell`) and `retry()`
/// (`FeedEmptyView`) — both sugar over `fetch(_:)`.
///
/// `pipeline` — the one injected seam — is assigned by the `.feed(_:)` modifier from its
/// configuration. It stays `nil` when no `apiBaseURL` is configured (Personal app) — every
/// operation no-ops.
///
/// `@Observable` solely so `.feed(_:)` can scope it by type and `@Feed` can read it back —
/// every stored property is untracked; observable UI state lives in `state`.
@MainActor
@Observable
public final class FeedModel<Input: PageableQuery> {

    /// Observable UI state — scoped for feed components by `.feed(_:)` / `.feedControls(_:)`.
    public let state = FeedState()

    // MARK: - Session (convenience copies for the parameterless controls)

    /// The active session: its input and latest receipt, as last successfully fetched —
    /// `loadMore()` continues them.
    @ObservationIgnored
    private var activeInput: Input?

    @ObservationIgnored
    private var latestPage: FeedPage?

    /// The last **attempted** page-1 input — recorded before the fetch, so a failed first
    /// load is retryable. Continuations never touch it: a quiet page-3 failure must not
    /// redefine what "Try Again" retries.
    @ObservationIgnored
    private var lastInput: Input?

    /// The in-flight fetch. Page-1 requests cancel and replace it (supersede); a superseded
    /// task touches no state and its caller converges on the successor's result, so a late
    /// resumption can never overwrite a newer commit.
    @ObservationIgnored
    private var activeFetch: Task<Outcome, Never>?

    // MARK: - The seam (assigned by the `.feed(_:)` modifier)

    /// The composed fetch pipeline: `Input → nextCursor`, upserting into the local store as a
    /// side effect. `nil` = no backend configured; all operations no-op.
    @ObservationIgnored
    var pipeline: (@MainActor (Input) async throws -> String?)?

    /// Label used in log messages ("posts", "quotes", …).
    @ObservationIgnored
    private let label: String

    public init(label: String = "feed") {
        self.label = label
    }

    // MARK: - Fetch (the one entry point)

    /// Fetches `input` — the input decides everything. Without a cursor it's a page-1 request:
    /// fires immediately, **supersedes** whatever is in flight (last submitted input wins),
    /// fails loudly, and browse additionally records `lastFetched`. With a cursor it's a
    /// continuation: never interrupts (dropped while anything runs) and fails quietly — a
    /// paging hiccup on a populated list shouldn't blank the screen.
    ///
    /// Returns the committed page's receipt for the view to store, or `nil` on failure —
    /// keep your previous paging state in that case. A superseded call returns the **winning
    /// request's** result instead of its own, so concurrent callers all assign the same truth
    /// no matter the order they resume in.
    @discardableResult
    public func fetch(_ input: Input) async -> FeedPage? {
        let firstPage = input.cursor == nil
        if firstPage {
            lastInput = input
            state.isSearching = input.isSearch
        }
        guard pipeline != nil else { return nil }
        if firstPage {
            activeFetch?.cancel()
        } else if state.loading != nil {
            return nil
        }
        state.loading = firstPage ? .refresh : .page

        let task = Task { await perform(input) }
        activeFetch = task

        // Converge on the winner: a superseded request hands back its successor's result, so
        // every concurrent caller assigns the same receipt no matter when it resumes — a stale
        // `nil` can never overwrite a newer commit.
        var awaited = task
        var outcome = await awaited.value
        while case .superseded = outcome, let successor = activeFetch, successor != awaited {
            awaited = successor
            outcome = await awaited.value
        }
        return outcome.page
    }

    // MARK: - Session continuations (sugar over fetch, for the parameterless controls)

    /// Fetches the next page of the active session — the same input, threaded with the last
    /// fresh cursor. Exists for self-contained controls (`FeedLoadMoreCell`) that can't
    /// construct an `Input` themselves.
    public func loadMore() async {
        guard state.loading == nil, state.hasMore,
              let input = activeInput, let cursor = latestPage?.nextCursor else { return }
        await fetch(input.page(after: cursor))
    }

    /// Re-fires the last attempted page-1 input — the input re-classifies itself, so this works
    /// for browse and search alike. No-op before the first attempt.
    public func retry() async {
        guard let lastInput else { return }
        await fetch(lastInput)
    }

    // MARK: - Execution

    /// What became of a fetch.
    private enum Outcome {
        /// Committed — carries the receipt.
        case fetched(FeedPage)
        /// Failed for real (not a cancellation); already logged and surfaced.
        case failed
        /// Cancelled because a newer page-1 request took over — no state was touched.
        case superseded

        var page: FeedPage? {
            if case .fetched(let page) = self { page } else { nil }
        }
    }

    /// The tracked unit of work: pipeline → commit → state updates, run as `activeFetch`.
    /// Every form of cancellation becomes `.superseded`, and a superseded run touches no
    /// state — the successor owns it all.
    private func perform(_ input: Input) async -> Outcome {
        guard let pipeline else { return .superseded }
        let firstPage = input.cursor == nil
        do {
            let nextCursor = try await pipeline(input)
            guard !Task.isCancelled else { return .superseded }
            let page = commit(input: input, nextCursor: nextCursor)
            if firstPage {
                state.lastError = nil
                if !input.isSearch { state.lastFetched = .now }
            }
            state.loading = nil
            return .fetched(page)
        } catch {
            if Task.isCancelled || Self.isCancellation(error) { return .superseded }
            Logger.feed.error("Feed '\(self.label)' fetch failed: \(error)")
            if firstPage {
                state.lastError = LoadError(error)
                if input.isSearch { state.hasMore = false }
            }
            state.loading = nil
            return .failed
        }
    }

    // MARK: - Bookkeeping

    /// Commits a fetched page: remembers the session for `loadMore()`, settles `hasMore`, and
    /// bumps `revision` so manual store readers re-query. Returns the view's receipt.
    private func commit(input: Input, nextCursor: String?) -> FeedPage {
        let page = FeedPage(
            nextCursor: nextCursor,
            frontier: nextCursor.flatMap { raw in
                (try? Date(raw, strategy: .iso8601))
                    ?? (try? Date(raw, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
            }
        )
        activeInput = input
        latestPage = page
        state.hasMore = nextCursor != nil
        state.revision += 1
        return page
    }

    /// Seeds `lastFetched` from persisted storage — a no-op once any value exists, so a live
    /// refresh is never overwritten by a stale stored date.
    func seed(lastFetched date: Date?) {
        guard state.lastFetched == nil, let date else { return }
        state.lastFetched = date
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

extension FeedModel where Input == CatalogueSyncQuery {

    /// Fetch sugar for the input-less `.catalogue` sync feed.
    @discardableResult
    public func fetch() async -> FeedPage? {
        await fetch(CatalogueSyncQuery())
    }
}

extension Logger {
    static let feed = Logger(subsystem: "me.tmbr", category: "feed")
}
