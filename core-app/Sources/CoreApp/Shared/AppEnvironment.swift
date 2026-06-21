import SwiftUI

public extension EnvironmentValues {

    /// Whether the app surfaces authoring affordances (create/edit). Default `false` — read-only.
    /// Author sets this from its sign-in state; Reader and Personal leave it `false`.
    @Entry var canAuthor: Bool = false
}
