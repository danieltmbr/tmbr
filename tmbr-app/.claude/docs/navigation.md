# Navigation Architecture

Scoped navigation using a `NavigationModel` registry. Each feature owns its own navigation state; views access it through a `@Navigation` property wrapper.

---

## Why Not One Big Navigation Model

`@Observable` gives fine-grained reactivity — SwiftUI only re-renders a view when a property it *actually reads* changes. If all navigation state lives in a single observable class, any navigation change anywhere re-evaluates every view that reads the model. Feature-owned scope classes isolate observation: a `CatalogueNavigation` change doesn't affect views that only read `AuthNavigation`.

---

## NavigationModel

A registry that holds feature-owned scope objects. Created once at app startup and injected via environment.

```swift
@MainActor
@Observable
public final class NavigationModel {

    private var scopes: [ObjectIdentifier: AnyObject] = [:]

    public init() {}

    public func register<S: AnyObject>(_ scope: S) {
        scopes[ObjectIdentifier(S.self)] = scope
    }

    public func scope<S: AnyObject>(_ type: S.Type) -> S {
        guard let scope = scopes[ObjectIdentifier(type)] as? S else {
            fatalError("Navigation scope '\(S.self)' not registered. Call register() before building the view hierarchy.")
        }
        return scope
    }
}
```

---

## @Navigation Property Wrapper

Same pattern as `@NowPlaying` — reads keypaths from the model for fine-grained reactivity.

```swift
@MainActor
@propertyWrapper
public struct Navigation<Value>: DynamicProperty {

    @Environment(NavigationModel.self)
    private var model

    private let get: @MainActor (NavigationModel) -> Value
    private let set: @MainActor (NavigationModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    public init(_ path: KeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    public init(_ path: ReferenceWritableKeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
```

---

## Feature Scope Classes

Each feature defines its own `@Observable` navigation class. The class lives in the feature package. Access control enforces isolation: `public` properties are the API for other packages; `internal` (no modifier) properties are the feature's private routing details.

```swift
// In the Catalogue feature package
@MainActor
@Observable
public final class CatalogueNavigation {

    // Public: other packages can trigger catalogue item detail
    public var selectedItemID: PreviewID?

    // Internal: only the catalogue feature reads/writes these
    var isFilterSheetPresented = false
    var selectedFilterTypes: Set<CatalogueItemType> = []
}
```

`NavigationModel` gets a computed property extension so callsites are ergonomic:

```swift
// In the Catalogue package
extension NavigationModel {
    var catalogue: CatalogueNavigation { scope(CatalogueNavigation.self) }
}
```

Usage in a view:

```swift
struct CatalogueView: View {
    @Navigation(\.catalogue.selectedItemID) private var selectedItem
    @Navigation(\.catalogue.isFilterSheetPresented) private var isFilterSheetPresented

    var body: some View {
        NavigationSplitView {
            // ...
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            FilterSheet()
        }
    }
}
```

---

## App Startup

All scopes registered in one place, before the view hierarchy is built:

```swift
@main
struct TmbrApp: App {

    private let navigation: NavigationModel = {
        let model = NavigationModel()
        model.register(CatalogueNavigation())
        model.register(AuthNavigation())
        model.register(NoteNavigation())
        return model
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(navigation)
        }
    }
}
```

---

## Access Control as the Enforcement Mechanism

Module-level access control is what makes this pattern safe. The `isFilterSheetPresented` property above has no `public` modifier — it's `internal` to the Catalogue package. Code in the App target or other feature packages cannot read or set it. The only way to open the filter sheet from outside Catalogue is to add a `public` trigger property that the sheet listens to.

This is intentional. It means other features can *initiate* navigations into Catalogue (e.g. deep-linking to a song from the Now Playing screen) without being able to control Catalogue's internal routing state.
