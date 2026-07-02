import Foundation
import SwiftData
import TmbrCore

/// A persistence façade for blog posts and their embedded quotes.
///
/// Wraps a SwiftData `ModelContext`. Folding `context.save()` into each call keeps callers
/// free of dual-step save boilerplate.
@MainActor
public struct PostStore {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Upserts `responses` into the store and saves. Idempotent: existing records are updated
    /// in-place; new server IDs create fresh `PostRecord`s. Post-sourced quotes embedded in
    /// each response are reconciled alongside the post.
    ///
    /// Indexes the existing rows once rather than per-item `#Predicate` fetches (SwiftData
    /// mistranslates the optional-`Int` `serverID == id` comparison and traps).
    public func upsert(_ responses: [PostResponse]) throws {
        var bySID: [Int: PostRecord] = [:]
        for record in try context.fetch(FetchDescriptor<PostRecord>()) {
            if let sid = record.serverID { bySID[sid] = record }
        }
        var quotesByPost: [Int: [QuoteRecord]] = [:]
        for quote in try context.fetch(FetchDescriptor<QuoteRecord>()) {
            if let pid = quote.postServerID { quotesByPost[pid, default: []].append(quote) }
        }
        for response in responses {
            if let existing = bySID[response.id] {
                existing.update(from: response)
            } else {
                let record = PostRecord()
                record.update(from: response)
                context.insert(record)
                bySID[response.id] = record
            }
            reconcilePostQuotes(response.quotes, forPostServerID: response.id, into: &quotesByPost)
        }
        try context.save()
    }

    // MARK: - Private

    /// Quote reconcile for a single post: upsert embedded quotes by `serverID`; delete `.synced`
    /// quotes absent from the incoming array (blockquote removed from post content).
    private func reconcilePostQuotes(
        _ quotes: [QuoteResponse],
        forPostServerID postID: PostID,
        into byPost: inout [Int: [QuoteRecord]]
    ) {
        let incomingIDs = Set(quotes.map(\.id))
        var current = byPost[postID] ?? []

        current.removeAll { quote in
            if quote.syncState == .synced, !incomingIDs.contains(quote.serverID) {
                context.delete(quote)
                return true
            }
            return false
        }

        for quote in quotes {
            let record = current.first { $0.serverID == quote.id } ?? {
                let new = QuoteRecord()
                context.insert(new)
                current.append(new)
                return new
            }()
            record.update(from: quote)
        }

        byPost[postID] = current
    }
}
