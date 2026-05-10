struct ComposeItemViewModel: Encodable, Sendable {
    let label: String
    let icon: Icon
    let url: String
}

struct ComposeSectionViewModel: Encodable, Sendable {
    let items: [ComposeItemViewModel]
    let hasSeparatorAfter: Bool
}

struct ComposePopupViewModel: Encodable, Sendable {

    let sections: [ComposeSectionViewModel]

    init?(_ definition: ComposeDefinition) {
        guard !definition.sections.isEmpty else { return nil }
        self.sections = definition.sections.enumerated().map { idx, section in
            ComposeSectionViewModel(
                items: section.entries.map { action, _ in
                    ComposeItemViewModel(label: action.label, icon: action.icon, url: action.url)
                },
                hasSeparatorAfter: idx < definition.sections.count - 1
            )
        }
    }
}
