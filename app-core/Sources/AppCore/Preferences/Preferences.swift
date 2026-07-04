import SwiftUI

/// Scoped access to `PreferencesModel` — a view re-renders only for the keypath it reads.
///
/// Usage:
/// ```swift
/// @Preferences(\.selectedLanguages) private var selectedLanguages   // read-only
/// @Preferences(\.selectedLanguages) private var selectedLanguages   // read-write ($selectedLanguages)
/// ```
///
/// Mirrors the `@Catalogue` / `@Blog` house pattern.
@MainActor
@propertyWrapper
public struct Preferences<Value>: DynamicProperty {

    @Environment(PreferencesModel.self)
    private var model

    private let get: @MainActor (PreferencesModel) -> Value
    private let set: @MainActor (PreferencesModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    public init(_ path: KeyPath<PreferencesModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    public init(_ path: ReferenceWritableKeyPath<PreferencesModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
