import Foundation

/// Reconciles a source's freshly-extracted blockquote bodies with its
/// previously-materialised quote rows, preserving persistent UUIDs across edits.
///
/// ## Algorithm
///
/// 1. **Exact-text match** — each fresh body is matched against the first existing
///    row with identical text. That row's UUID and `created_at` are preserved.
///    Handles unchanged quotes and pure reordering.
///
/// 2. **Residual pairing** — unmatched old rows and unmatched new bodies are paired
///    in document order. The pair keeps the old UUID and updates the body in place.
///    Makes a typo-fix preserve a shared `/quotes/<id>` link.
///
/// 3. **Surplus new** bodies get a fresh UUID (insert).
///
/// 4. **Surplus old** rows are scheduled for deletion (the blockquote was removed).
///
/// ## Future consideration: fuzzy / edit-distance matching
///
/// The one edge case residual pairing handles poorly is a quote **edited and moved
/// in the same save**: order-pairing may pair the wrong old row.  A future upgrade
/// could replace step 2 with Levenshtein similarity scoring (pair the best-scoring
/// old × new pairs above a threshold). Trade-offs: threshold tuning is required,
/// and two similar-but-distinct quotes can be silently mis-paired.  Adopt only if
/// real-world "edit + move in one save" churn is observed breaking links in practice.
/// The `plan` function is the single integration point for that upgrade.
public struct QuoteReconciler {

    public struct IdentifiedBody: Sendable {
        public let id: UUID
        public let body: String

        public init(id: UUID, body: String) {
            self.id = id
            self.body = body
        }
    }

    public struct ReconcileActions: Sendable {
        /// IDs of existing rows whose body was unchanged — no write needed.
        public let unchanged: [UUID]
        /// Existing rows to update in place (id → new body).
        public let toUpdate: [(id: UUID, body: String)]
        /// New bodies to insert with a fresh UUID.
        public let toInsert: [String]
        /// IDs of existing rows to delete (blockquote removed from source).
        public let toDelete: [UUID]
    }

    /// Returns the set of DB operations needed to reconcile `existing` rows with
    /// `freshBodies`. Pure function — no IO, fully testable.
    public static func plan(
        existing: [IdentifiedBody],
        freshBodies: [String]
    ) -> ReconcileActions {
        var unmatchedExisting = existing
        var unmatchedFresh: [String] = []
        var unchanged: [UUID] = []

        // Phase 1: greedy exact-text matching
        for body in freshBodies {
            if let idx = unmatchedExisting.firstIndex(where: { $0.body == body }) {
                unchanged.append(unmatchedExisting[idx].id)
                unmatchedExisting.remove(at: idx)
            } else {
                unmatchedFresh.append(body)
            }
        }

        // Phase 2: residual pairing in document order
        let pairCount = min(unmatchedExisting.count, unmatchedFresh.count)
        let toUpdate: [(id: UUID, body: String)] = (0..<pairCount).map { i in
            (id: unmatchedExisting[i].id, body: unmatchedFresh[i])
        }

        let toInsert = Array(unmatchedFresh.dropFirst(pairCount))
        let toDelete = unmatchedExisting.dropFirst(pairCount).map(\.id)

        return ReconcileActions(
            unchanged: unchanged,
            toUpdate: toUpdate,
            toInsert: toInsert,
            toDelete: Array(toDelete)
        )
    }
}
