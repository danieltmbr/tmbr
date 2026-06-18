import Foundation
import SwiftData
import CoreApi
import CoreApp
import CoreTmbr

/// Reader's lazy data-in for the blog: on refresh, fetch the public posts list (unauthenticated) and
/// upsert it into the local store. `@Query` in `BlogTab` renders the result reactively. No tombstones,
/// no `since` cursor — Reader is a stale-while-revalidate cache, fetching the most recent page.
@MainActor
final class ReaderPosts {
    private let baseURL: URL
    private let context: ModelContext

    init(baseURL: URL, context: ModelContext) {
        self.baseURL = baseURL
        self.context = context
    }

    func refreshPosts() async throws {
        let loader = RequestLoader(request: PostsRequest.postQuery(baseURL: baseURL), session: .shared)
        let page = try await loader.load(from: PageQuery(limit: 50))
        try PostRecord.upsert(page.items, in: context)
        try context.save()
    }
}
