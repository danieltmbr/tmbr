import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth

struct Metadata: @unchecked Sendable {

    let json: [String: Any]

    let tags: [String: String]

    let multiTags: [String: [String]]

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

        var headers = HTTPHeaders()
        headers.add(name: .userAgent, value: "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)")
        headers.add(name: .accept, value: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
        headers.add(name: .acceptEncoding, value: "identity")
        headers.add(name: .acceptLanguage, value: "en-US,en;q=0.9")

        let response = try await client.get(URI(string: url.absoluteString), headers: headers)

        guard (200..<300).contains(response.status.code) else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Upstream returned \(response.status.code)")
        }
        guard let body = response.body else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Response HTML is invalid or missing")
        }
        guard let data = body.getData(at: 0, length: body.readableBytes) else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Response HTML is invalid or missing")
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Response HTML is invalid or missing")
        }

        let parsed = parser.parse(html: html)

        guard let type = parsed.tags["og:type"] else {
            throw Abort(.badGateway, reason: "Metadata fetch failed. Unidentified media type.")
        }

        return Metadata(
            json: parsed.json,
            tags: parsed.tags,
            multiTags: parsed.multiTags,
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
