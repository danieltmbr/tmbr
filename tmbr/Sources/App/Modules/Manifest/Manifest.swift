import Vapor
import Core

struct Manifest: Module {
    
    func configure(_ app: Vapor.Application) async throws {}
    
    func boot(_ app: Vapor.Application) async throws {
        app.get("manifest.json") { request in
            let model = ManifestModel(
                name: Environment.webApp.appName,
                display: "standalone",
                start_url: Environment.webApp.startURL,
                scope: "/",
                icons: [
                    ManifestModel.Icon(
                        src: "/Assets/Icons/icon-512~dark.png",
                        size: CGSize(width: 512, height: 512),
                        type: "image/png"
                    )
                ]
            )
            let response = Response(status: .ok)
            try response.content.encode(model)
            return response
        }
    }
}

private struct ManifestModel: Content {
    
    struct Icon: Codable {
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
    
    static var defaultContentType: HTTPMediaType {
        HTTPMediaType(
            type: "application",
            subType: "manifest+json",
            parameters: ["charset" : "utf-8"]
        )
    }
}


extension Module where Self == Manifest {
    static var manifest: Self {
        Manifest()
    }
}
