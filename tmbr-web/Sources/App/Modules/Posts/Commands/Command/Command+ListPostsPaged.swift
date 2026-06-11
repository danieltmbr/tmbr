import Foundation
import Vapor
import Core
import Fluent
import TmbrCore

struct ListPostsPagedInput: Sendable {
    let since: Date?
    let before: Date?
    let limit: Int

    init(since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.since = since
        self.before = before
        self.limit = limit
    }
}

extension Command where Self == PlainCommand<ListPostsPagedInput, [Post]> {

    // preferredLanguages comes from request.languagePreference — same as listPosts
    static func listPostsPaged(database: Database, preferredLanguages: Set<String>?) -> Self {
        PlainCommand { input in
            let languages = preferredLanguages?.compactMap(Language.init(rawValue:))
            var query = Post.query(on: database)
                .filter(\.$state == .published)
                .languages(languages)
                .sort(\.$createdAt, .descending)
                .with(\.$author)
                .with(\.$attachment) { attachment in attachment.with(\.$image) }

            if let since = input.since {
                query = query.filter(\.$createdAt > since)
            }
            if let before = input.before {
                query = query.filter(\.$createdAt < before)
            }

            return try await query.limit(input.limit).all()
        }
    }
}

extension CommandFactory<ListPostsPagedInput, [Post]> {

    static var listPostsPaged: Self {
        CommandFactory { request in
            .listPostsPaged(
                database: request.commandDB,
                preferredLanguages: request.languagePreference
            )
            .logged(name: "List posts paged", logger: request.logger)
        }
    }
}
