import Foundation
import Fluent
import CoreTmbr

public protocol TimestampedModel: Timestamped, Model {
    static var createdAtPath: KeyPath<Self, FieldProperty<Self, Date>> { get }
}

public extension QueryBuilder where Model: TimestampedModel {
    @discardableResult
    func page(_ input: PageInput) -> Self {
        if let since = input.since { filter(Model.createdAtPath > since) }
        if let before = input.before { filter(Model.createdAtPath < before) }
        return limit(input.limit + 1)
    }
}
