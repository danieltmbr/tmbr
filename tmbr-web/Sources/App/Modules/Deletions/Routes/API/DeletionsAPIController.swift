import Vapor
import CoreTmbr

struct DeletionsAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("api", "sync", "deletions") { req async throws -> [DeletionRecord] in
            let user = try await req.permissions.deletions.list()
            let since = try? req.query.decode(DeletionQuery.self).since
            let input = ListDeletionsInput(since: since, userID: user?.userID)
            let deletions = try await req.commands.deletions.list(input)
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
