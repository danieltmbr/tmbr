import Foundation
import SwiftData
import CoreTmbr

public extension PostRecord {

    /// Overwrites this record from a server `PostResponse` (a synced pull — no local pending state).
    func update(from response: PostResponse) {
        serverID = response.id
        title = response.title
        content = response.content
        state = response.state
        language = response.language
        createdAt = response.createdAt
        publishedAt = response.publishedAt
        attachmentID = response.attachment?.id
        attachmentTitle = response.attachment?.primaryInfo
        syncState = .synced
    }

    /// Upserts pulled posts by `serverID` (fetch-before-insert dedup — there is no `@Attribute(.unique)`).
    /// Indexes the existing rows once rather than per-item `#Predicate` fetches (SwiftData mistranslates
    /// the optional-`Int` `serverID == id` comparison and traps). Run on the `@MainActor` context.
    static func upsert(_ responses: [PostResponse], in context: ModelContext) throws {
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
    }
}
