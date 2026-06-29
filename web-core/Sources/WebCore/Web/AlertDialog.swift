public struct AlertDialog: Encodable, Sendable {

    public struct Action: Encodable, Sendable {
        public let id: String
        public let label: String
        public let href: String?

        public init(id: String, label: String, href: String? = nil) {
            self.id = id
            self.label = label
            self.href = href
        }
    }

    public let id: String
    public let message: String
    public let primaryAction: Action
    public let secondaryAction: Action

    public init(id: String, message: String, primaryAction: Action, secondaryAction: Action) {
        self.id = id
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

extension Template where Model == AlertDialog {
    public static let alertDialog = Template(name: "Shared/alert-dialog")
}
