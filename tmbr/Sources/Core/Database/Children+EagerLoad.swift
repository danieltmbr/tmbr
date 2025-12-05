import Foundation
import Fluent

extension ChildrenProperty {
    @discardableResult
    public func load<Relation>(
        on db: Database,
        include keyPath: KeyPath<To, Relation>
    ) async throws -> [To]
    where Relation: EagerLoadable, Relation.From == To {
        try await query(on: db).with(keyPath).all()
    }
}
