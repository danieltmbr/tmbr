import Foundation

public actor AuthProvider {
    
    private var token: String?
    
    private var refreshTask: Task<String, Error>?
    
    private let refresher: (@Sendable () async throws -> String)?

    public init(
        token: String? = nil,
        refresher: @escaping @Sendable () async throws -> String
    ) {
        self.token = token
        self.refresher = refresher
    }

    public var value: String? { token }

    public func refreshedToken() async throws -> String {
        if let task = refreshTask { return try await task.value }
        let task = Task { [refresher] in try await refresher() }
        refreshTask = task
        do {
            let fresh = try await task.value
            token = fresh
            refreshTask = nil
            return fresh
        } catch {
            refreshTask = nil
            throw error
        }
    }

    public func set(_ token: String?) {
        self.token = token
    }
}
