import Foundation
import Fluent

public struct ModelConfiguration<Model, Parameters>: Sendable
where Model: Fluent.Model & Sendable, Parameters: Sendable {

    private let configure: @Sendable (inout Model, Parameters) -> Void
    
    public init(configure: @Sendable @escaping (inout Model, Parameters) -> Void) {
        self.configure = configure
    }
    
    public func callAsFunction(_ model: inout Model, with parameters: Parameters) {
        configure(&model, parameters)
    }
}
