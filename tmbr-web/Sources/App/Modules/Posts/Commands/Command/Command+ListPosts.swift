import Foundation
import Vapor
import WebCore
import Logging
import Fluent
import TmbrCore

struct ListPostsInput: Sendable {
    let query: PostQueryPayload
    let page: PageInput?
}

extension Command where Self == PlainCommand<ListPostsInput, [Post]> {

    static func listPosts(database: Database, preferredLanguages: Set<String>?) -> Self {
        PlainCommand { input in
            let languages = preferredLanguages?.compactMap(Language.init(rawValue:))
            var query = Post.query(on: database)
                .filter(\.$state == .published)
                .languages(languages)

            let safeTerm = input.query.term.flatMap { t -> String? in
                let trimmed = t.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }
            if let safeTerm {
                query = query.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "posts.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "posts.content ILIKE '%\(safeTerm)%'"))
                }
            }

            query = query
                .with(\.$author)
                .with(\.$attachment) { attachment in attachment.with(\.$image) }
                .with(\.$quotes)

            if let page = input.page {
                query.sort(\.$createdAt, .descending)
                query.page(page)
            } else {
                query = query.sort(\.$publishedAt, .descending)
            }

            return try await query.all()
        }
    }
}

extension CommandFactory<ListPostsInput, [Post]> {

    static var listPosts: Self {
        CommandFactory { request in
            .listPosts(database: request.commandDB, preferredLanguages: request.languagePreference)
            .logged(name: "List posts", logger: request.logger)
        }
    }
}
