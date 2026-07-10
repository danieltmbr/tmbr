import SwiftUI
import SwiftData
import AppApi
import AppPersistence
import TmbrCore

/// The recipe for one feed: its identity (`label`) and how to compose the network loader and
/// store upsert into the fetch pipeline. Everything else the feed needs to drive itself comes
/// from the `Input`'s own `PageableQuery` conformance.
///
/// The feature's parent view applies it with **one call** — `.feed(.posts)` — which owns the
/// `FeedModel`, wires its pipeline from the environment (`apiBaseURL`, `urlSession`,
/// `modelContext`), persists its freshness stamp (`userDefaults`), and scopes the model, its
/// `FeedState`, and the control actions for the subtree. Children read the model back with
/// `@Feed`, and components like `FeedStatusLine` read `\.feedState` / `\.loadFeed` /
/// `\.retryFeed`.
///
/// Previews and tests pass a stub recipe instead:
///
/// ```swift
/// PostsList(languages: [], searchText: "")
///     .feed(FeedConfiguration(
///         label: "posts",
///         loader: { _, _ in PostsLoader { _ in PageResult(items: mockPosts, nextCursor: nil) } },
///         upsert: { try PostStore(context: $0).upsert($1.items) },
///         nextCursor: { $0.nextCursor }
///     ))
/// ```
public struct FeedConfiguration<Input: PageableQuery>: Sendable {

    /// Persistence key (`feed.<label>.lastFetched`) and log tag.
    let label: String

    /// Composes the feed's fetch pipeline — `Input → nextCursor`, upserting as a side effect —
    /// from per-app config.
    let makeFetch: @MainActor (URL, URLSession, ModelContext) -> (@MainActor (Input) async throws -> String?)

    /// Raw composition — for feeds that aren't a paged loader+upsert pipeline (e.g. the
    /// catalogue `SyncGroup` refresh). Prefer the typed initializer for paged endpoints.
    public init(
        label: String,
        makeFetch: @escaping @MainActor (URL, URLSession, ModelContext) -> (@MainActor (Input) async throws -> String?)
    ) {
        self.label = label
        self.makeFetch = makeFetch
    }

    /// Typed composition for a paged endpoint. Keeps the loader's `Response` and the upserter's
    /// input matched at compile time; `Response` is erased into the composed fetch, so the
    /// configuration stays generic over `Input` alone.
    public init<Response: Decodable & Sendable>(
        label: String,
        loader: @escaping @Sendable (URL, URLSession) -> RequestLoader<Input, Response>,
        upsert: @escaping @MainActor (ModelContext, Response) throws -> Void,
        nextCursor: @escaping @Sendable (Response) -> String?
    ) {
        self.init(label: label) { baseURL, session, context in
            let loader = loader(baseURL, session)
            return { input in
                let response = try await loader.load(from: input)
                try upsert(context, response)
                return nextCursor(response)
            }
        }
    }
}

// MARK: - Feeds

extension FeedConfiguration where Input == PostsQuery {

    /// Blog posts — browse, search, and paging over `GET /api/posts` into `PostStore`.
    public static var posts: Self {
        FeedConfiguration(
            label: "posts",
            loader: { PostsLoader.posts(baseURL: $0, session: $1) },
            upsert: { try PostStore(context: $0).upsert($1.items) },
            nextCursor: { $0.nextCursor }
        )
    }
}

extension FeedConfiguration where Input == QuotesQuery {

    /// Quotes — browse, search, and paging over `GET /api/quotes` into `CatalogueStore`.
    public static var quotes: Self {
        FeedConfiguration(
            label: "quotes",
            loader: { QuotesLoader.quotes(baseURL: $0, session: $1) },
            upsert: { try CatalogueStore(context: $0).upsert($1.items) },
            nextCursor: { $0.nextCursor }
        )
    }
}

extension FeedConfiguration where Input == CatalogueSearchQuery {

    /// Catalogue search — search + paging over `GET /api/catalogue/search` (previews and notes)
    /// into `CatalogueStore`. Search-only: browse refresh is the `.catalogue` feed.
    public static var catalogueSearch: Self {
        FeedConfiguration(
            label: "catalogueSearch",
            loader: { CatalogueSearchLoader.searchCatalogue(baseURL: $0, session: $1) },
            upsert: { try CatalogueStore(context: $0).upsertSearch($1) },
            nextCursor: { $0.nextCursor }
        )
    }
}

extension FeedConfiguration where Input == CatalogueSyncQuery {

    /// Catalogue browse refresh — runs the full catalogue `SyncGroup` (typed lists + orphans +
    /// categories). Not paged: the returned cursor is always `nil`, so `loadMore()` never fires.
    public static var catalogue: Self {
        FeedConfiguration(label: "catalogue") { baseURL, _, context in
            let store = CatalogueStore(context: context)
            return { _ in
                try await SyncGroup.catalogue(baseURL: baseURL, store: store).run()
                return nil
            }
        }
    }
}

// MARK: - The one-call modifier

/// Owns the `FeedModel` for one feed and provisions the subtree: wires the fetch pipeline from
/// the environment, persists the freshness stamp, then scopes the model (for `@Feed`), its
/// `FeedState`, and the control actions (for `FeedStatusLine` / `FeedLoadMoreCell` /
/// `FeedEmptyView`).
private struct FeedModifier<Input: PageableQuery>: ViewModifier {

    @Environment(\.apiBaseURL)
    private var baseURL

    @Environment(\.urlSession)
    private var session

    @Environment(\.modelContext)
    private var context

    @Environment(\.userDefaults)
    private var userDefaults

    @State
    private var model: FeedModel<Input>

    private let configuration: FeedConfiguration<Input>

    init(configuration: FeedConfiguration<Input>) {
        self.configuration = configuration
        self._model = State(wrappedValue: FeedModel(label: configuration.label))
    }

    func body(content: Content) -> some View {
        wirePipeline()
        return content
            .environment(model)
            .feedControls(model)
            // The freshness stamp is persisted reactively — the model just records the date.
            .onChange(of: model.state.lastFetched) { _, date in
                guard let date else { return }
                userDefaults.set(date, forKey: lastFetchedKey)
            }
    }

    /// Re-composes the model's fetch pipeline from the current environment. Runs on every body
    /// evaluation; the assigned properties are not observation-tracked, so this never
    /// invalidates the view. (`apiBaseURL`, `urlSession`, and `userDefaults` are effectively
    /// constant, so re-evaluations are rare and the work is assigning a closure.)
    private func wirePipeline() {
        guard let baseURL else {
            model.pipeline = nil
            return
        }
        model.pipeline = configuration.makeFetch(baseURL, session, context)
        model.seed(lastFetched: userDefaults.object(forKey: lastFetchedKey) as? Date)
    }

    private var lastFetchedKey: String {
        "feed.\(configuration.label).lastFetched"
    }
}

public extension View {

    /// Provisions a feed for this subtree with a single call: creates and owns its `FeedModel`,
    /// wires the fetch pipeline, and scopes the model + state + control actions so descendants
    /// can use `@Feed`, `FeedStatusLine`, `FeedLoadMoreCell`, and `FeedEmptyView` with no
    /// further wiring.
    ///
    /// When one subtree hosts several feeds (e.g. catalogue browse + search), the shared
    /// component keys (`\.feedState`, `\.loadFeed`, `\.retryFeed`) follow the innermost
    /// `.feed(_:)` — re-scope explicitly with `.feedControls(_:)` where it matters.
    func feed<Input>(_ configuration: FeedConfiguration<Input>) -> some View {
        modifier(FeedModifier(configuration: configuration))
    }
}
