import SwiftUI

/// App-injected account control for the tab toolbars (e.g. Author's sign-in / account button).
///
/// The shared UI knows *where* an account affordance goes, not *what* it is — each app injects its own
/// (Author: a sign-in/account button + sheet; Reader: nothing). Keeps `CoreApp` free of auth.
public struct AccountToolbar: Sendable {

    let content: @MainActor @Sendable () -> AnyView

    public init(@ViewBuilder content: @escaping @MainActor @Sendable () -> some View) {
        self.content = { AnyView(content()) }
    }

    /// No account affordance (Reader / read-only apps).
    public static let none = AccountToolbar { EmptyView() }
}

public extension EnvironmentValues {

    /// Whether the app surfaces authoring affordances (create/edit). Default `false` — read-only.
    /// Author sets this from its sign-in state; Reader leaves it `false`.
    @Entry var canAuthor: Bool = false

    /// The app-injected account toolbar item shown in the Blog/Catalogue tabs.
    @Entry var accountToolbar: AccountToolbar = .none
}
