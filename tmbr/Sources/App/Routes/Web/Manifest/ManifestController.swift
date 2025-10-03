import Foundation
import Vapor

import Vapor

struct ManifestController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("manifest.json") { request in
            let model = Manifest(
                name: Environment.webApp.appName,
                display: "standalone",
                start_url: Environment.webApp.startURL,
                scope: "/",
                icons: [
                    Manifest.Icon(
                        src: "/Assets/Icons/icon-512~dark.png",
                        size: CGSize(width: 512, height: 512),
                        type: "image/png"
                    )
                ]
            )
            let data = try JSONEncoder().encode(model)
            var headers = HTTPHeaders()
            headers.replaceOrAdd(
                name: .contentType,
                value: "application/manifest+json; charset=utf-8"
            )
            return Response(
                status: .ok,
                headers: headers,
                body: .init(data: data)
            )
        }
    }
}

private struct Manifest: Encodable {
    struct Icon: Encodable {
        private let src: String
        
        private let sizes: String
        
        private let type: String
        
        init(src: String, size: CGSize, type: String) {
            self.src = src
            self.sizes = "\(Int(size.width))x\(Int(size.height))"
            self.type = type
        }
    }
    
    private let name: String
    
    private let display: String
    
    private let start_url: String
    
    private let scope: String
    
    private let icons: [Icon]
    
    init(
        name: String,
        display: String,
        start_url: String,
        scope: String,
        icons: [Icon]
    ) {
        self.name = name
        self.display = display
        self.start_url = start_url
        self.scope = scope
        self.icons = icons
    }
}
