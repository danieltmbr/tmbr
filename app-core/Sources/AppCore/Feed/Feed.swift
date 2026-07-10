import SwiftUI

/// Reads the nearest feed's `FeedModel` — the counterpart of the parent's `.feed(_:)` call,
/// which creates the model, wires its pipeline, and scopes it into the environment. A missing
/// `.feed(_:)` ancestor fails fast with SwiftUI's missing-environment diagnostic.
///
/// Feeds are keyed by their `Input` type; name it either through the wrapped type or the
/// initializer — whichever reads better at the site:
/// ```swift
/// // parent
/// PostsList(query: query).feed(.posts)
///
/// // child — equivalent forms
/// @Feed(PostsQuery.self) private var posts
/// @Feed private var posts: FeedModel<PostsQuery>
///
/// .task(id: query) { await posts.fetch(query) }    // the input decides browse vs search
/// ```
@MainActor @propertyWrapper
public struct Feed<Input: PageableQuery>: DynamicProperty {

    @Environment(FeedModel<Input>.self)
    private var model

    public init() {}

    /// Inference aid: names the feed by its `Input` type so the property needs no annotation.
    public init(_ inputType: Input.Type) {}

    public var wrappedValue: FeedModel<Input> { model }
}
