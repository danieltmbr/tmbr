import Foundation
import SwiftData
import AppPersistence
import TmbrCore

/// Observable engine that drives catalogue text search against the local SwiftData store.
///
/// The engine delegates the actual fetching and merging to `CatalogueStore.search(...)`, which runs
/// two predicate-filtered `FetchDescriptor` queries — one over `PreviewRecord` (title/subtitle) and
/// one over `NoteRecord` (body) — and resolves the cross-model note→preview join via a targeted
/// predicate fetch of only the needed IDs.
///
/// This class exists because manual fetches don't trigger SwiftUI `@Query` reactivity — views observe
/// `engine.results` via `@Observable` instead.
///
/// **Usage pattern** (from the view's `.task(id: searchText)`):
/// 1. Call `search(term:in:categories:languages:)` immediately — renders cached results.
/// 2. Await the network search action — it upserts newly-fetched results into the store.
/// 3. Call `search(...)` again — picks up the upserted data.
@MainActor
@Observable
public final class CatalogueSearchEngine {

    /// The current search results, updated synchronously on each `search(...)` call.
    public private(set) var results: [CatalogueSearchResult] = []

    public init() {}

    /// Runs the search via `CatalogueStore` and updates `results` synchronously.
    /// Clears results when `term` is blank.
    public func search(
        term: String,
        in context: ModelContext,
        categories: Set<CatalogueCategory>,
        languages: Set<Language>
    ) {
        guard !term.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        do {
            results = try CatalogueStore(context: context).search(
                term: term,
                categories: categories,
                languages: languages
            )
        } catch {
            results = []
        }
    }

    public func clear() {
        results = []
    }
}
