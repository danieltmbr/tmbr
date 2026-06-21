import SwiftUI

/// A toolbar button that is only visible when the app surfaces authoring affordances.
///
/// Self-gating on `canAuthor` — renders nothing in Reader and Personal. Callers provide
/// the icon and action; they never need to read `canAuthor` themselves.
struct AuthoringButton: View {

    @Environment(\.canAuthor)
    private var canAuthor

    let systemImage: String
    let action: () -> Void

    var body: some View {
        if canAuthor {
            Button(action: action) {
                Image(systemName: systemImage)
            }
        }
    }
}
