import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct EditInput<Model, Parameters>: Sendable
where Model: Fluent.Model & Sendable, Parameters: Sendable {
    
    fileprivate let id: Model.IDValue
    
    fileprivate let parameters: Parameters
    
    init(id: Model.IDValue, parameters: Parameters) {
        self.id = id
        self.parameters = parameters
    }
}

extension PlainCommand where Output: Fluent.Model {
    
    static func edit<Parameters: Sendable>(
        configure: ModelConfiguration<Output, Parameters>,
        database: Database,
        permission: AuthPermissionResolver<Output>,
        validate: Validator<Parameters>
    ) -> Self
    where Input == EditInput<Output, Parameters> {
        PlainCommand { input in
            guard var item = try await Output.find(input.id, on: database) else {
                throw Abort(.notFound, reason: "\(Output.self) not found")
            }
            try await permission.grant(item)
            try validate(input.parameters)
            
            configure(&item, with: input.parameters)
            try await item.save(on: database)
                    
            return item
        }
    }
    
    static func edit<Parameters: Sendable>(
        configure: ModelConfiguration<Output, Parameters>,
        database: Database,
        permission: AuthPermissionResolver<Output>,
        queryNotes: CommandResolver<QueryNotesInput, [Note]>,
        validate: Validator<Parameters>
    ) -> Self
    where Input == EditInput<Output, Parameters>,
          Output: Previewable {
        PlainCommand { input in
            guard var item = try await Output.find(input.id, on: database) else {
                throw Abort(.notFound, reason: "\(Output.self) not found")
            }
            try await permission.grant(item)
            try validate(input.parameters)
            
            let oldAccess = item.access
            configure(&item, with: input.parameters)
            try await item.save(on: database)
            
            if oldAccess == .public && item.access == .private {
                let notes = try await queryNotes(for: item)
                notes.forEach { $0.access = $0.access && item.access }
                try await notes.update(on: database)
            }
            
            return item
        }
    }
}

extension CommandResolver {
    
    func callAsFunction<Item, Parameters>(
        _ itemID: Item.IDValue,
        with parameters: Parameters
    ) async throws -> Output
    where Item: Model & Sendable,
          Parameters: Sendable,
          Input == EditInput<Item, Parameters>
    {
        let input = EditInput<Item, Parameters>(
            id: itemID,
            parameters: parameters
        )
        return try await self.callAsFunction(input)
    }
}
