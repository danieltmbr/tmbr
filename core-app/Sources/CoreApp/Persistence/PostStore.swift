import Foundation
import SwiftData
import CoreTmbr

/// A persistence façade for blog posts.
///
/// Wraps a SwiftData `ModelContext` and delegates to the well-tested `PostRecord.upsert` static
/// method. Folding `context.save()` into the call keeps callers free of dual-step save boilerplate.
@MainActor
public struct PostStore {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Upserts `responses` into the store and saves. Idempotent: existing records are updated
    /// in-place; new server IDs create fresh `PostRecord`s.
    public func upsert(_ responses: [PostResponse]) throws {
        try PostRecord.upsert(responses, in: context)
        try context.save()
    }
}
