struct FilterItemViewModel: Encodable, Sendable {
        
    let checked: Bool

    let iconName: String
    
    let label: String

    let value: String
    
    init(
        checked: Bool = false,
        iconName: String,
        label: String,
        value: String
    ) {
        self.checked = checked
        self.iconName = iconName
        self.label = label
        self.value = value
    }
    
    func check(_ checked: Bool) -> Self {
        Self(
            checked: checked,
            iconName: iconName,
            label: label,
            value: value
        )
    }
}
