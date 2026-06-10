import SwiftUI

@MainActor
@propertyWrapper
struct Blog<Value>: DynamicProperty {

    @Environment(BlogModel.self)
    private var model

    private let get: @MainActor (BlogModel) -> Value
    private let set: @MainActor (BlogModel, Value) -> Void

    var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    init(_ path: KeyPath<BlogModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    init(_ path: ReferenceWritableKeyPath<BlogModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
