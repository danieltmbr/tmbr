import SwiftUI
import SwiftData

/// Scoped access to `BlogModel` — a view re-renders only for the keypath it reads (`@Blog(\.status)`),
/// not on every model change. Mirrors the house `@NowPlaying` wrapper.
@MainActor
@propertyWrapper
public struct Blog<Value>: DynamicProperty {

    @Environment(BlogModel.self)
    private var model

    private let get: @MainActor (BlogModel) -> Value
    
    private let set: @MainActor (BlogModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    public init(_ path: KeyPath<BlogModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    public init(_ path: ReferenceWritableKeyPath<BlogModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
