import SwiftUI

@MainActor
@propertyWrapper
struct Catalogue<Value>: DynamicProperty {

    @Environment(CatalogueModel.self)
    private var model

    private let get: @MainActor (CatalogueModel) -> Value
    private let set: @MainActor (CatalogueModel, Value) -> Void

    var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    init(_ path: KeyPath<CatalogueModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    init(_ path: ReferenceWritableKeyPath<CatalogueModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
