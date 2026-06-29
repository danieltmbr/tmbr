/// The account affordance state injected by each app target.
///
/// `.unavailable` is the default — Reader and Personal never set it, so no account UI appears.
/// Author drives it from `AccountModel.isSignedIn`.
public enum AccountStatus: Hashable, Sendable {
    /// This app target has no account UI (Reader, Personal). Account controls render nothing.
    case unavailable
    /// Account UI is present but the user is not signed in. Shows a sign-in prompt.
    case signedOut
    /// The user is signed in.
    case signedIn
}
