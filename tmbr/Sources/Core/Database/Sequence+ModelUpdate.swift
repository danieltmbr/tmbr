import Foundation
import Fluent

extension Sequence where Element: Model {
    public func update(on database: any Database) async throws {
        try await map { $0.update(on: database) }
            .flatten(on: database.eventLoop)
            .get()
    }
}
