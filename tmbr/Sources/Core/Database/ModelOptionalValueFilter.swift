import Fluent

infix operator ~~?

public extension QueryBuilder {
    @discardableResult
    func filter(_ filter: ModelOptionalValueFilter<Model>) -> Self {
        self.filter(Model.self, filter)
    }
    
    @discardableResult
    func filter<Joined>(
        _ schema: Joined.Type,
        _ filter: ModelOptionalValueFilter<Joined>
    ) -> Self
    where Joined: Schema
    {
        guard let value = filter.value else { return self }
        if case .array(let array) = value, array.isEmpty { return self }
        return self.filter(
            .extendedPath(filter.path, schema: Joined.schemaOrAlias, space: Joined.spaceIfNotAliased),
            filter.method,
            value
        )
    }
}

public struct ModelOptionalValueFilter<Model>: Sendable where Model: Fields {
    init<Field>(
        _ lhs: KeyPath<Model, Field>,
        _ method: DatabaseQuery.Filter.Method,
        _ rhs: DatabaseQuery.Value?
    )
    where Field: QueryableProperty
    {
        self.path = Model.path(for: lhs)
        self.method = method
        self.value = rhs
    }
    
    let path: [FieldKey]
    let method: DatabaseQuery.Filter.Method
    let value: DatabaseQuery.Value?
}

public func ~~? <Model, Field, Values>(lhs: KeyPath<Model, Field>, rhs: Values?) -> ModelOptionalValueFilter<Model>
where Model: FluentKit.Schema,
      Field: QueryableProperty,
      Values: Collection,
      Values.Element == Field.Value
{
    lhs ~~? rhs.map { values in
        .array(values.map { Field.queryValue($0) })
    }
}

public func ~~? <Model, Field>(lhs: KeyPath<Model, Field>, rhs: DatabaseQuery.Value?) -> ModelOptionalValueFilter<Model>
where Model: FluentKit.Schema, Field: QueryableProperty
{
    ModelOptionalValueFilter(lhs, .subset(inverse: false), rhs)
}
