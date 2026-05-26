import Foundation

public actor AuthToken {
    public private(set) var value: String?

    public init(value: String? = nil) {
        self.value = value
    }

    public func set(_ value: String?) {
        self.value = value
    }
}
