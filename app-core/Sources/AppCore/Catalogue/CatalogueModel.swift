import Foundation
import AppPersistence

/// Headless model for the Catalogue tab — tracks the active category filter.
///
/// Empty = no filter (show all). Browse refresh lives in the `.catalogue` feed
/// (`@Feed(.catalogue)`); search + paging in the `.catalogueSearch` feed.
@MainActor
@Observable
public final class CatalogueModel {

    /// Categories currently active in the filter. Empty = no filter (show all).
    public var selectedCategories: Set<CatalogueCategory> = []

    public init() {}
}
