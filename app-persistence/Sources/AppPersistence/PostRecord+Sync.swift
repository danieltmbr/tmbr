import Foundation
import SwiftData
import TmbrCore

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

}
