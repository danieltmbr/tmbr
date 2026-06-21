import SwiftUI

/// Property wrapper for reading account state in views.
///
/// Usage:
/// ```swift
/// @Account(\.isSignedIn) private var isSignedIn
/// ```
@MainActor
@propertyWrapper
public struct Account<Value>: DynamicProperty {

    @Environment(AccountModel.self)
    private var model

    private let get: @MainActor (AccountModel) -> Value
    private let set: @MainActor (AccountModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    /// Read-only access.
    public init(_ path: KeyPath<AccountModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write access — `$property` gives a Binding.
    public init(_ path: ReferenceWritableKeyPath<AccountModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
