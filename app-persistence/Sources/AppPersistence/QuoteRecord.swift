import Foundation
import SwiftData
import TmbrCore

/// Local representation of a stable quote extracted from a note or a blog post.
///
/// `serverID` is the stable `QuoteID` assigned by the backend and preserved across
/// source edits by `QuoteReconciler`. Quotes are server-derived (never created
/// on-device) so `serverID` is the sole identity — there is no `clientKey`.
///
/// Source is exposed via the `source` computed property (`.note(NoteID)` or
/// `.post(PostID)`), backed by internal storage so query/cascade code within the
/// module can still index and filter by raw id fields.
///
/// Display fields are denormalised so a future Quotes view renders standalone
/// without loading other records.
@Model
public final class QuoteRecord {

    public var serverID: UUID = UUID()

    public var body: String = ""

    public var createdAt: Date = Date.now

    // MARK: - Source (internal backing)

    var sourceKindRaw: String = "note"

    /// Set when source is `.note`. Internal — callers use `source`.
    var noteServerID: UUID?

    /// Set when source is `.post`. Internal — callers use `source`.
    var postServerID: Int?

    // MARK: - Denormalised source display fields

    public var sourceTitle: String = ""

    public var sourceSubtitle: String?

    /// Category type slug ("song", "book", …). Blog-post-sourced quotes store the
    /// `blogPostsSource` sentinel so the field is always non-optional and queryable
    /// without nil-coalescing in SwiftData predicates.
    public var sourceType: String = QuoteRecord.blogPostsSource

    /// PreviewID of the source catalogue item. nil for post-sourced quotes.
    public var sourcePreviewID: UUID?

    /// Language of the source note or post, populated at sync time.
    /// Empty string until the first sync (empty = unknown = always visible in language filter).
    var languageRaw: String = ""

    var syncStateRaw: String = SyncState.synced.rawValue

    public init() {}
}

// MARK: - Source enum

public extension QuoteRecord {

    /// Polymorphic source of a quote.
    enum Source: Sendable {
        case note(NoteID)
        case post(PostID)
    }

    var source: Source? {
        get {
            if sourceKindRaw == Self.kindPost {
                return postServerID.map { .post($0) }
            }
            return noteServerID.map { .note($0) }
        }
        set { newValue.map { setSource($0) } }
    }
}

// MARK: - Language

public extension QuoteRecord {
    /// The language of the source note or post.
    ///
    /// `nil` until the first sync that populates this field, or for quotes whose source
    /// was added before language tracking was introduced. `nil` = unknown = always visible.
    var language: Language? {
        get { Language(rawValue: languageRaw) }
        set { languageRaw = newValue?.rawValue ?? "" }
    }

    /// Sentinel for blog-post-sourced quotes. Internal so sync code (same module) can write it;
    /// callers outside AppPersistence use `QuoteSourceFilter.blogPosts` instead.
    static let blogPostsSource = "__blog_posts__"

    static func list(sources: Set<QuoteSourceFilter>, languages: Set<Language>) -> Predicate<QuoteRecord> {
        let sourcesArray = Array(sources.map { filter -> String in
            switch filter {
            case .category(let category): return category.rawValue
            case .blogPosts: return blogPostsSource
            }
        })
        let codes = languages.map(\.rawValue)
        return #Predicate<QuoteRecord> { quote in
            (sourcesArray.isEmpty || sourcesArray.contains(quote.sourceType)) &&
            (codes.isEmpty || quote.languageRaw.isEmpty || codes.contains(quote.languageRaw))
        }
    }

    /// Predicate for the quotes list — text search when `term` is non-empty, plain list
    /// otherwise; source and language filters always apply. Mirrors what the server returns
    /// for the same inputs, so one set of inputs drives both the local `@Query` and the
    /// network fetch.
    static func quotes(term: String, sources: Set<QuoteSourceFilter>, languages: Set<Language>) -> Predicate<QuoteRecord> {
        if !term.isEmpty {
            search(term: term, sources: sources, languages: languages)
        } else {
            list(sources: sources, languages: languages)
        }
    }

    /// Predicate for in-tab text search. Matches quotes whose body contains `term`
    /// (case-insensitive, locale-aware), filtered by active source and language selections.
    static func search(term: String, sources: Set<QuoteSourceFilter>, languages: Set<Language>) -> Predicate<QuoteRecord> {
        let sourcesArray = Array(sources.map { filter -> String in
            switch filter {
            case .category(let category): return category.rawValue
            case .blogPosts: return blogPostsSource
            }
        })
        let codes = languages.map(\.rawValue)
        return #Predicate<QuoteRecord> { quote in
            quote.body.localizedStandardContains(term) &&
            (sourcesArray.isEmpty || sourcesArray.contains(quote.sourceType)) &&
            (codes.isEmpty || quote.languageRaw.isEmpty || codes.contains(quote.languageRaw))
        }
    }
}

// MARK: - SyncState

public extension QuoteRecord {
    var syncState: SyncState {
        get { SyncState(rawValue: syncStateRaw) ?? .synced }
        set { syncStateRaw = newValue.rawValue }
    }
}

// MARK: - Internal helpers

extension QuoteRecord {

    static let kindNote = "note"
    static let kindPost = "post"

    func setSource(_ source: Source) {
        switch source {
        case .note(let id):
            sourceKindRaw = Self.kindNote
            noteServerID = id
            postServerID = nil
        case .post(let id):
            sourceKindRaw = Self.kindPost
            postServerID = id
            noteServerID = nil
        }
    }
}
