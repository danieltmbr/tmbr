import Vapor
import TmbrCore

struct DeletionsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "sync", "deletions") { req async throws -> [DeletionRecord] in
            let since = try? req.query.decode(DeletionQuery.self).since
            let deletions = try await req.commands.deletions.list(since)
            return deletions.compactMap { deletion -> DeletionRecord? in
                guard let type = DeletionType(rawValue: deletion.type) else { return nil }
                return DeletionRecord(type: type, itemID: deletion.itemID, deletedAt: deletion.deletedAt)
            }
        }
    }
}

private struct DeletionQuery: Decodable, Sendable {
    let since: Date?
}
