import SwiftUI

/// Scoped access to `QuotesModel` (`@Quotes(\.selectedSources)`), mirroring `@Catalogue`.
@MainActor
@propertyWrapper
public struct Quotes<Value>: DynamicProperty {

    @Environment(QuotesModel.self)
    private var model

    private let get: @MainActor (QuotesModel) -> Value
    private let set: @MainActor (QuotesModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    public init(_ path: KeyPath<QuotesModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    public init(_ path: ReferenceWritableKeyPath<QuotesModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
