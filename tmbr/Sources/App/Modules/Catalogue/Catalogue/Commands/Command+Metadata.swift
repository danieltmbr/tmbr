import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

struct Metadata: Sendable {
    
    let data: [String: String]
    
    let type: String

    let url: URL
}

struct FetchMetadataCommand: Command {
    
    private let client: Client
    
    private let parser: HTMLMetadataParser
    
    private let permission: AuthPermissionResolver<Void>
    
    init(
        client: Client,
        parser: HTMLMetadataParser = .init(),
        permission: AuthPermissionResolver<Void>
    ) {
        self.client = client
        self.parser = parser
        self.permission = permission
    }
    
    func execute(_ url: URL) async throws -> Metadata {
        try await permission.grant()
        
        let response = try await client.get(URI(string: url.absoluteString))
        
        guard response.status == .ok else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Upstream returned \(response.status.code)")
        }
        guard let body = response.body,
              let data = body.getData(at: 0, length: body.readableBytes),
              let html = String(data: data, encoding: .utf8) else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Response HTML is invalid or missing")
        }
        
        let metadata = parser.parse(html: html)
        
        guard let type = metadata["og:type"] else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Unidentified media type.")
        }
        
        return Metadata(
            data: metadata,
            type: type,
            url: url
        )
    }
}

extension CommandFactory<URL, Metadata> {
    
    static var fetchMetadata: Self {
        CommandFactory { request in
            FetchMetadataCommand(
                client: request.client,
                permission: request.permissions.catalogue.metadata
            )
            .logged(logger: request.logger)
        }
    }
}
