import Foundation

public struct DeletionRecord: Codable, Sendable {

    public let type: DeletionType

    public let itemID: String

    public let deletedAt: Date

    public init(type: DeletionType, itemID: String, deletedAt: Date) {
        self.type = type
        self.itemID = itemID
        self.deletedAt = deletedAt
    }
}
