import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct BlogTab: View {

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State
    private var searchText = ""

    @State
    private var showEditor = false

    @State
    private var showLanguageFilter = false

    var body: some View {
        NavigationStack {
            PostsList(
                languages: selectedLanguages,
                searchText: searchText
            )
            .feed(.posts)
            .navigationTitle("Blog")
            .searchable(text: $searchText, prompt: "Search posts…")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showLanguageFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button { showLanguageFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .popover(isPresented: $showLanguageFilter) {
                        LanguageFilterView()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $showLanguageFilter) {
            LanguageFilterView()
        }
#endif
        .sheet(isPresented: $showEditor) {
            PostEditor()
        }
    }
}

// MARK: - Unified list (browse and search)

private struct PostsList: View {

    @Feed(PostsQuery.self)
    private var feed

    /// The view's paging state — the source of truth for what to fetch next. Reset on every
    /// new intent, updated from the receipt of each committed fetch.
    @State
    private var page: FeedPage?

    @Query
    private var posts: [PostRecord]

    private let languages: Set<Language>

    private let searchText: String

    init(
        languages: Set<Language>,
        searchText: String
    ) {
        self.languages = languages
        self.searchText = searchText
        _posts = Query(
            filter: PostRecord.blog(term: searchText, languages: languages),
            sort: \PostRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        List {
            if !posts.isEmpty {
                FeedStatusLine()
            }
            ForEach(posts) { post in
                NavigationLink(value: post) {
                    PostCell(
                        title: post.title,
                        date: post.publishedAt ?? post.createdAt
                    )
                }
                .onAppear { [createdAt = post.createdAt] in
                    Task { await fetch(after: createdAt) }
                }
            }
            if !posts.isEmpty {
                FeedLoadMoreCell()
            }
        }
        .overlay {
            if posts.isEmpty {
                FeedEmptyView {
                    ContentUnavailableView("No posts yet", systemImage: "doc.text")
                }
            }
        }
        .navigationDestination(for: PostRecord.self) { post in
            PostReaderView(
                title: post.title,
                content: post.content,
                created: post.createdAt,
                published: post.publishedAt
            )
        }
        .refreshable {
            await fetch(page: nil)
        }
        // Runs on appear and restarts on any term or filter change (the id is the page-1
        // query) — the model supersedes in-flight requests, so the last input wins.
        .task(id: query()) {
            await fetch(page: nil)
        }
    }

    /// Fetches for the given paging state — `nil` is page 1 — and folds the receipt back in.
    /// The `?? page` fallback is the failure policy: a failed page 1 falls back to `nil`
    /// (no dead sessions), while a failed next page falls back to its own pre-call state,
    /// so a later row appearance retries it.
    private func fetch(page: FeedPage?) async {
        self.page = await feed.fetch(query(page: page)) ?? page
    }

    /// Row-driven paging: a row at or past the fetched frontier is unverified local cache —
    /// fetch the next page for it. The `nextCursor` check gates exhaustion: without it, an
    /// exhausted page would build a cursor-less query and restart the session as page 1.
    private func fetch(after createdAt: Date) async {
        guard let page, page.nextCursor != nil,
              let frontier = page.frontier,
              createdAt <= frontier else { return }
        await fetch(page: page)
    }

    private func query(page: FeedPage? = nil) -> PostsQuery {
        PostsQuery(
            cursor: page?.nextCursor,
            languages: languages,
            term: searchText
        )
    }
}
