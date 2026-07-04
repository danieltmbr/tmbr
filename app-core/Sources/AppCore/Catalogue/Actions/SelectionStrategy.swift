import Foundation

/// Determines how a new set of elements is merged into the current selection.
public struct SelectionStrategy<Element: Hashable>: Sendable {

    let apply: @Sendable (_ current: Set<Element>, _ incoming: Set<Element>) -> Set<Element>

    /// Replaces the current selection with the incoming set.
    public static var override: SelectionStrategy {
        SelectionStrategy { _, incoming in incoming }
    }

    /// Toggles each incoming element: already-selected → remove, not-selected → add.
    public static var toggle: SelectionStrategy {
        SelectionStrategy { current, incoming in
            incoming.reduce(into: current) { set, element in
                if set.contains(element) { set.remove(element) } else { set.insert(element) }
            }
        }
    }
}
