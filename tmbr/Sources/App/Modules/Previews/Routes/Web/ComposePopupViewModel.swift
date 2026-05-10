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
}
