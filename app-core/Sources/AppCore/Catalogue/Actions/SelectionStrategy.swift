import Foundation

/// Determines how a new set of category slugs is merged into the current selection.
public struct SelectionStrategy: Sendable {

    let apply: @Sendable (_ current: Set<String>, _ incoming: Set<String>) -> Set<String>

    /// Replaces the current selection with the incoming set.
    public static let override = SelectionStrategy { _, incoming in incoming }

    /// Toggles each incoming slug: already-selected → remove, not-selected → add.
    public static let toggle = SelectionStrategy { current, incoming in
        incoming.reduce(into: current) { set, slug in
            if set.contains(slug) { set.remove(slug) } else { set.insert(slug) }
        }
    }
}
