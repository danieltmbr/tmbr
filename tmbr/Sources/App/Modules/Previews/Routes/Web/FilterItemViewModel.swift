struct FilterItemViewModel: Encodable, Sendable {
        
    let checked: Bool

    let icon: String
    
    let label: String

    let value: String
    
    init(
        checked: Bool = false,
        icon: String,
        label: String,
        value: String
    ) {
        self.checked = checked
        self.icon = icon
        self.label = label
        self.value = value
    }
    
    func check(_ checked: Bool) -> Self {
        Self(
            checked: checked,
            icon: icon,
            label: label,
            value: value
        )
    }
}
