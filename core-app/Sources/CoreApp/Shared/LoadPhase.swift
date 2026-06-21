import Foundation

/// Lifecycle of a screen's background refresh. The UI renders cache (`@Query`) regardless; `phase`
/// just drives empty/loading/error affordances. Reader's "not yet cached" case is `.loading` over an
/// empty `@Query`.
public enum LoadPhase: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(LoadError)
}
