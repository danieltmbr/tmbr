import Foundation
import Vapor
import Core
import Logging
import Fluent
import TmbrCore

extension Command where Self == PlainCommand<PostQueryPayload, [Post]> {

    static func listPosts(database: Database, preferredLanguages: Set<String>?) -> Self {
        PlainCommand { query in
            let languages = preferredLanguages?.compactMap(Language.init(rawValue:))
            var builder = Post.query(on: database)
                .filter(\.$state == .published)
                .languages(languages)

            let safeTerm = query.term.flatMap { t -> String? in
                let trimmed = t.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : trimmed.replacingOccurrences(of: "'", with: "''")
            }
            if let safeTerm {
                builder = builder.group(.or) { group in
                    group.filter(.sql(unsafeRaw: "posts.title ILIKE '%\(safeTerm)%'"))
                    group.filter(.sql(unsafeRaw: "posts.content ILIKE '%\(safeTerm)%'"))
                }
            }

            return try await builder
                .sort(\.$publishedAt, .descending)
                .with(\.$author)
                .all()
        }
    }
}

extension CommandFactory<PostQueryPayload, [Post]> {

    static var listPosts: Self {
        CommandFactory { request in
            .listPosts(database: request.commandDB, preferredLanguages: request.languagePreference)
            .logged(
                name: "List posts",
                logger: request.logger
            )
        }
    }
}
