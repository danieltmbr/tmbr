import Fluent

public protocol AsyncLoadable: Sendable {
    func load(on database: any Database) async throws
}

extension OptionalParentProperty: AsyncLoadable {}

extension ParentProperty: AsyncLoadable {}

extension OptionalChildProperty: AsyncLoadable {}

extension ChildrenProperty: AsyncLoadable {}
