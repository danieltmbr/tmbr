# SwiftUI Architecture

Patterns for building tmbr-app. Examples use `NowPlaying` as the worked domain — MusicKit now-playing is the first real feature — so everything here maps directly to what we'll actually build.

---

## Shared Observable Model

Use `@MainActor @Observable final class` for any model whose state is shared across multiple views.

```swift
@MainActor
@Observable
final class NowPlayingModel {
    var track: Track?
    var isPlaying: Bool = false
    var progress: Double = 0

    func togglePlay() { isPlaying.toggle() }
    func seek(to value: Double) { progress = value }
}
```

**Rules:**
- Never pass the model through `init` parameters. Inject it once at the root and let descendant views read from the environment.
- A single `View` extension modifier injects the model and all its action keys together:

```swift
extension View {
    func nowPlaying(_ model: NowPlayingModel) -> some View {
        environment(model)
            .environment(\.togglePlay, TogglePlayAction(model: model))
            .environment(\.seek, SeekAction(model: model))
    }
}
```

- Call `.nowPlaying(model)` once on the root view. Every descendant that needs anything from `NowPlayingModel` reads it from the environment.

---

## Custom Property Wrappers for Environment Models

Reading `@Environment(NowPlayingModel.self)` in every view gives up fine-grained reactivity — the view re-renders whenever *any* property changes, not just the ones it reads. The fix is a custom property wrapper that captures a keypath.

```swift
@MainActor
@propertyWrapper
public struct NowPlaying<Value>: DynamicProperty {

    @Environment(NowPlayingModel.self)
    private var model

    private let get: @MainActor (NowPlayingModel) -> Value
    private let set: @MainActor (NowPlayingModel, Value) -> Void

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }

    // Read-only access
    public init(_ path: KeyPath<NowPlayingModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    // Read-write access — $ gives a Binding
    public init(_ path: ReferenceWritableKeyPath<NowPlayingModel, Value>) {
        get = { $0[keyPath: path] }
        set = { model, value in model[keyPath: path] = value }
    }
}
```

Usage in a view:

```swift
struct PlaybackProgressBar: View {
    @NowPlaying(\.progress) private var progress
    @NowPlaying(\.isPlaying) private var isPlaying

    var body: some View {
        ProgressView(value: progress)
            .opacity(isPlaying ? 1 : 0.5)
    }
}
```

**Naming convention:** name the wrapper for its subject, not the value type — `@NowPlaying`, `@Navigation`. It reads as "a property of NowPlaying".

---

## Action Pattern

Actions are thin, single-responsibility wrappers over model operations. They are injected via environment keys so views never receive model references or closures in their `init`.

```swift
@MainActor
public struct TogglePlayAction: Sendable {

    private let body: @MainActor () -> Void

    // For defaults and tests — no model needed
    nonisolated public init(_ body: @escaping @MainActor () -> Void = {}) {
        self.body = body
    }

    // Bound to a real model
    @MainActor
    public init(model: NowPlayingModel) {
        self.init { model.togglePlay() }
    }

    @MainActor
    public func callAsFunction() { body() }
}
```

**Rules:**
- One struct = one responsibility. `TogglePlayAction` toggles. `SeekAction` seeks. Never merge.
- The `nonisolated` closure init is the default/test path. The `@MainActor` model-bound init is production.
- `callAsFunction()` makes the action callable without a method name: `togglePlay()`.
- Never store a model reference directly in an action — capture the operation as a closure at init time.

---

## Environment Key Declaration

All environment keys for a feature live in one file: `[Feature]Environment.swift`. Use the `@Entry` macro.

```swift
// NowPlayingEnvironment.swift
extension EnvironmentValues {
    @Entry public var togglePlay: TogglePlayAction = TogglePlayAction()
    @Entry public var seek: SeekAction = SeekAction()
}
```

The root injection modifier sets concrete values — descendant views read from environment, never from a model or service directly:

```swift
extension View {
    func nowPlaying(_ model: NowPlayingModel) -> some View {
        environment(model)
            .environment(\.togglePlay, TogglePlayAction(model: model))
            .environment(\.seek, SeekAction(model: model))
    }
}
```

---

## Atomic Controls

Controls are self-contained. They read state via property wrappers and call actions from the environment. No state passed in via init.

```swift
public struct PlayToggle: View {

    @NowPlaying(\.isPlaying)
    private var isPlaying

    @Environment(\.togglePlay)
    private var togglePlay

    public init() {}

    public var body: some View {
        Button {
            togglePlay()
        } label: {
            Label(
                isPlaying ? "Pause" : "Play",
                systemImage: isPlaying ? "pause.fill" : "play.fill"
            )
        }
        .contentTransition(.symbolEffect(.replace))
    }
}
```

**Anti-patterns:**
- Don't pass closures in `init` for side effects — use environment action keys instead
- Don't use `@StateObject` or `ObservableObject` — use `@Observable` + `@Environment`
- Don't read `@Environment(NowPlayingModel.self)` directly — use the typed property wrapper

---

## Style Protocol Pattern

For views that need multiple layout variants, define a `Style` protocol. This is the same pattern SwiftUI uses for `ButtonStyle`, `LabelStyle`, etc.

```swift
public struct NowPlayingBarStyleConfiguration {
    public let track: Track?
    public let isPlaying: Bool
    public let togglePlay: TogglePlayAction
}

public protocol NowPlayingBarStyle: Sendable {
    typealias Configuration = NowPlayingBarStyleConfiguration
    associatedtype Body: View
    @MainActor @ViewBuilder func makeBody(configuration: Configuration) -> Body
}

// Static accessors — no public init on concrete types
public extension NowPlayingBarStyle where Self == CompactNowPlayingBarStyle {
    static var compact: CompactNowPlayingBarStyle { .init() }
}
```

**The public API view is a thin pass-through:**

```swift
public struct NowPlayingBar: View {

    @Environment(\.nowPlayingBarStyle) private var style
    @NowPlaying(\.track) private var track
    @NowPlaying(\.isPlaying) private var isPlaying
    @Environment(\.togglePlay) private var togglePlay

    public init() {}

    public var body: some View {
        style.makeBody(configuration: configuration)
    }

    private var configuration: NowPlayingBarStyleConfiguration {
        NowPlayingBarStyleConfiguration(track: track, isPlaying: isPlaying, togglePlay: togglePlay)
    }
}
```

**Concrete styles delegate to a `private struct` that owns interaction `@State`:**

```swift
public struct CompactNowPlayingBarStyle: NowPlayingBarStyle {
    public func makeBody(configuration: Configuration) -> some View {
        CompactNowPlayingBar(configuration: configuration)
    }
}

private struct CompactNowPlayingBar: View {
    let configuration: NowPlayingBarStyleConfiguration

    @State private var isPressed = false  // interaction state lives here, not in Configuration

    var body: some View {
        HStack {
            TrackArtwork(track: configuration.track)
            Spacer()
            Button { configuration.togglePlay() } label: {
                Image(systemName: configuration.isPlaying ? "pause.fill" : "play.fill")
            }
        }
    }
}
```

**Rules:**
- `Configuration` contains only data — bindings and action closures. No views, no `@State`.
- The public API view's `body` is a single `style.makeBody(configuration:)` call.
- Interaction `@State` (press animations, drag offsets, local value copies) lives in the private impl view.
- Styles are always reached via static accessors — never `CompactNowPlayingBarStyle()` directly.

---

## File Organisation

```
[Feature]/
├── [Feature]Model.swift          — @Observable model (no SwiftUI imports)
├── [Feature]Environment.swift    — @Entry environment key declarations
├── View+[Feature].swift          — root injection modifier
├── Actions/
│   ├── Toggle[Feature]Action.swift
│   └── Seek[Feature]Action.swift
├── Controls/
│   ├── [Control].swift
│   └── [Control]/
│       ├── [Control]Style.swift  — protocol + configuration
│       ├── System[Control]Style.swift
│       └── Compact[Control]Style.swift
└── Views/
    └── [FeatureBar].swift
```

For features large enough to split: `[Domain]Kit/` holds headless models (no SwiftUI), `[Domain]UI/` holds everything visual. Package dependencies flow downward only: Core → Kit → UI → Feature → App.
