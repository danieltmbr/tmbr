public protocol TokenProvider: Sendable {
    func fetchToken() async throws -> String
}
