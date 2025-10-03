import Vapor

struct Template<Model: Encodable>: Sendable {
    let name: String

    init(name: String) {
        self.name = name
    }

    @inlinable
    func render(_ model: Model, with renderer: ViewRenderer) async throws -> View {
        try await renderer.render(name, model)
    }
}

extension Template where Model == Never {
    @inlinable
    func render(with renderer: ViewRenderer) async throws -> View {
        try await renderer.render(name)
    }
}
