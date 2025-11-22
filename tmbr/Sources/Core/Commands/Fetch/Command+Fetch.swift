import Foundation

public enum FetchReason: Sendable {
    case read
    case write
}

public struct FetchParameters<ItemID: Sendable>: Sendable {
    public let itemID: ItemID
    
    public let reason: FetchReason
    
    init(itemID: ItemID, reason: FetchReason) {
        self.itemID = itemID
        self.reason = reason
    }
}

public extension CommandResolver {
    func callAsFunction<ItemID: Sendable>(_ itemID: ItemID, for reason: FetchReason) async throws -> Output
    where Input == FetchParameters<ItemID> {
        try await callAsFunction(FetchParameters(itemID: itemID, reason: reason))
    }
}
