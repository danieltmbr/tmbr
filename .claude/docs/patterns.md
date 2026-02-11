# Swift Design Patterns

## Closure-Based Functional Types

Prefer structs that wrap closures over protocols with multiple implementations. This pattern is used throughout the codebase:

```swift
struct PlatformChecker: Sendable {
    private let check: @Sendable (URL) -> Bool

    init(check: @escaping @Sendable (URL) -> Bool) {
        self.check = check
    }

    func matches(_ url: URL) -> Bool { check(url) }
}

extension PlatformChecker {
    static let appleMusic = PlatformChecker { url in
        url.host?.contains("music.apple.com") ?? false
    }
}
```

## Three-Initializer Pattern

For composable types that need to support both individual instances and aggregation:

1. **Functional init** — full control, accepts closures directly
2. **Convenience init** — common case, wraps simpler building blocks (checker, extractor, etc.)
3. **Composite init** — aggregates multiple instances, tries each in order

```swift
struct Platform<M>: Sendable {
    // 1. Functional - full control
    init(name: @escaping (URL) -> String?, metadata: @escaping (URL, Fetcher) async throws -> M?)

    // 2. Convenience - from building blocks
    init(name: String, checker: PlatformChecker, extractor: MetadataExtractor<M>? = nil)

    // 3. Composite - aggregation
    init(platforms: [Platform<M>])
}
```

## Static Factory Extensions

Define instances as static properties in type extensions, enabling dot-syntax:

```swift
extension Platform where M == SongMetadata {
    static let appleMusic = Platform(name: "Apple Music", checker: .appleMusic, extractor: .appleMusicSong)
    static let spotify = Platform(name: "Spotify", checker: .spotify)  // display-only
    static let all = Platform(platforms: [.appleMusic, .spotify, .youtube])
}
```

## Single Responsibility

Each type should do one thing. If a type is doing two things (e.g., URL validation AND ID extraction), split it. This makes pieces reusable and easier to reason about.

## Optional Capabilities

When some instances support a feature and others don't, make it optional rather than forcing all implementations to provide it:

```swift
init(name: String, checker: PlatformChecker, extractor: MetadataExtractor<M>? = nil)
// Platforms without extractors are "display-only" — they can identify URLs but not fetch metadata
```

## Collaboration Philosophy

**Discuss before implementing.** For non-trivial features, explore ideas through conversation first. Sketch out types, relationships, and responsibilities verbally before writing code. This surfaces design issues early and builds shared understanding.

**Question proposed abstractions.** If a design introduces a new type, ask: can this be achieved with a convenience initializer instead? Extra types add cognitive load — prefer fewer types with flexible initializers.
