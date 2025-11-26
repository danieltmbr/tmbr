import Vapor
import Fluent
import Foundation

actor PreviewService: Sendable {
    
    struct Key: StorageKey {
        typealias Value = PreviewService
    }
    
    private var providers: [String: any PreviewProvider] = [:]
    
    public func register(provider: any PreviewProvider) {
        providers[provider.type] = provider
    }
    
    public func preview(for type: String, id: Int, on request: Request) async throws -> Preview? {
        guard let provider = providers[type] else { return nil }
        return try await provider.preview(id: id, on: request)
    }
}

extension Application {
    var previewService: PreviewService {
        get throws {
            guard let service = storage[PreviewService.Key.self] else {
                throw Abort(.serviceUnavailable, reason: "Preview Service is unavailable.")
            }
            return service
        }
    }
}
