import Foundation
import Vapor

public struct Validator<Input: Sendable>: Sendable {
    
    private let validator: @Sendable (Input) throws -> Void
    
    public init(validate: @escaping @Sendable (Input) throws -> Void) {
        self.validator = validate
    }
    
    public func callAsFunction(_ input: Input) throws {
        try self.validator(input)
    }
    
    public func callAsFunction(_ inputs: [Input]) throws {
        var errors: [String] = []
        for (index, input) in inputs.enumerated() {
            do {
                try self.validator(input)
            } catch {
                errors.append("Item at index \(index) is invalid: \(error.localizedDescription)")
            }
        }
        guard !errors.isEmpty else { return }
        throw Abort(.badRequest, reason: errors.joined(separator: "\n"))
    }
}
