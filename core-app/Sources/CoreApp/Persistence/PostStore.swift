import Foundation
import SwiftData
import CoreTmbr

/// A persistence façade for blog posts.
///
/// Wraps a SwiftData `ModelContext`. Folding `context.save()` into the call keeps callers
/// free of dual-step save boilerplate.
@MainActor
public struct PostStore {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    /// Upserts `responses` into the store and saves. Idempotent: existing records are updated
    /// in-place; new server IDs create fresh `PostRecord`s.
    ///
    /// Indexes the existing rows once rather than per-item `#Predicate` fetches (SwiftData
    /// mistranslates the optional-`Int` `serverID == id` comparison and traps).
    public func upsert(_ responses: [PostResponse]) throws {
        var bySID: [Int: PostRecord] = [:]
        for record in try context.fetch(FetchDescriptor<PostRecord>()) {
            if let sid = record.serverID { bySID[sid] = record }
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
        }
        try context.save()
    }
}
