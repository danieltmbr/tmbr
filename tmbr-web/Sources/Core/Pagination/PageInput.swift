import Foundation

public struct PageInput: Sendable {
    public let since: Date?
    public let before: Date?
    public let limit: Int

    public init(since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.since = since
        self.before = before
        self.limit = limit
    }
}
