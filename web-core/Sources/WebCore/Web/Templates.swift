import Vapor

public struct Template<Model: Encodable>: Sendable {
    
    fileprivate let name: String

    public init(name: String) {
        self.name = name
    }

    public func render(_ model: Model, with renderer: ViewRenderer) async throws -> View {
        try await renderer.render(name, model)
    }
}

extension Template where Model == Never {

    public func render(with renderer: ViewRenderer) async throws -> View {
        try await renderer.render(name)
    }
}
