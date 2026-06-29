import SwiftUI

/// The refresh capability a domain detail section publishes up to its owning `List`. Equatable
/// by `id` (the item's previewID) so the preference is stable across re-renders. Marked
/// `@unchecked Sendable` because `run` is a `@MainActor` closure — it is only ever invoked on
/// the MainActor.
struct CatalogueItemRefresh: Equatable, @unchecked Sendable {
    let id: UUID
    let run: @MainActor () async throws -> Void
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

struct CatalogueItemRefreshKey: PreferenceKey {
    static let defaultValue: CatalogueItemRefresh? = nil
    static func reduce(value: inout CatalogueItemRefresh?, nextValue: () -> CatalogueItemRefresh?) {
        value = nextValue() ?? value
    }
}

extension View {
    /// Called by a domain detail section to publish its item-specific refresh closure up the
    /// view tree so `CatalogueItemDetailView` can run it on pull-to-refresh.
    func catalogueItemRefresh(id: UUID, _ run: @escaping @MainActor () async throws -> Void) -> some View {
        preference(key: CatalogueItemRefreshKey.self, value: .init(id: id, run: run))
    }
}

// MARK: - Box

/// `@MainActor @Observable` box that lets `onPreferenceChange` (which requires a `@Sendable`
/// handler) store the collected value without capturing `self` or raw `@State` projections.
@MainActor
@Observable
final class CatalogueItemRefreshBox {
    var value: CatalogueItemRefresh?
}
