import CoreTmbr

struct FilterPanelViewModel: Encodable, Sendable {
    let ariaLabel: String
    let icon: String
    let items: [FilterItemViewModel]
    let openButtonId: String
    let panelId: String
    let param: String
    let showSelectAll: Bool
}

extension FilterPanelViewModel {
    static func types(_ items: [FilterItemViewModel]) -> Self {
        Self(
            ariaLabel: "Filter",
            icon: "filter",
            items: items,
            openButtonId: "filter-open",
            panelId: "filter-panel",
            param: "types",
            showSelectAll: true
        )
    }

    static func languages(_ items: [FilterItemViewModel]) -> Self {
        Self(
            ariaLabel: "Language",
            icon: "globe",
            items: items,
            openButtonId: "language-open",
            panelId: "language-panel",
            param: "languages",
            showSelectAll: false
        )
    }
}
