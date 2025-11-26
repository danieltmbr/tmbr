import Foundation
import Fluent

extension ChildrenProperty where From: MediaItem, To: MediaResource<From> {
    func upsert(_ resource: To, on database: Database) async throws {
        try await delete(platform: resource.platform, on: database)
        try await resource.save(on: database)
        try await create(resource, on: database)
    }
    
    func upsert(_ resources: [To], on database: Database) async throws {
        try await delete(platforms: Set(resources.map(\.platform)), on: database)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for resource in resources {
                _ = group.addTaskUnlessCancelled {
                    try await resource.save(on: database)
                }
            }
            while try await group.next() != nil {}
        }
        try await create(resources, on: database)
    }
    
    func delete(platform: MediaPlatform<From>, on database: Database) async throws {
        try await self
            .query(on: database)
            .filter(\.$platform == platform)
            .delete()
    }
    
    func delete(platforms: Set<MediaPlatform<From>>, on database: Database) async throws {
        try await self
            .query(on: database)
            .filter(\.$platform ~~ platforms)
            .delete()
    }
}

