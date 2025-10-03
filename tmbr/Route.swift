//import Foundation
//import Vapor
//
//struct ManifestModel: Encodable {
//    let name: String
//    let startURL: String
//}
//
//struct Template<ViewModel>: Sendable where ViewModel: Encodable {
//    
//    private let render: @Sendable (ViewRenderer, ViewModel) async throws -> View
//    
//    init(render: @Sendable @escaping (ViewRenderer, ViewModel) async throws -> View) {
//        self.render = render
//    }
//    
//    init(_ name: String) {
//        self.init { renderer, model in
//            try await renderer.render(name, model)
//        }
//    }
//    
//    func render(model: ViewModel, with renderer: ViewRenderer) async throws -> View {
//        try await render(renderer, model)
//    }
//}
//
//extension Template where ViewModel == Never {
//    static let notifications = Template("notifications")
//    
//    func render(with renderer: ViewRenderer) async throws -> View {
//        try await render(renderer)
//    }
//}
//
//extension Template where ViewModel == ManifestModel {
//    static let manifest = Template("manifest")
//}
//
//struct Page {
//    
//    private let render: @Sendable (Request) async throws -> View
//    
//    init(
//        parse: @Sendable @escaping (Request) async throws -> Encodable,
//        render: @Sendable @escaping (ViewRenderer, Encodable) async throws -> View
//    ) {
//        self.parse = parse
//        self.render = render
//    }
//    
//    init<Model>(
//        _ template: Template<Model>,
//        parse: @Sendable @escaping (Request) async throws -> Model
//    ) where Model: Encodable, Model: Sendable {
//        self.init { request in
//            try await parse(request)
//        } render: { renderer, model in
//            try await renderer.render(template.name, model)
//        }
//    }
//}
//
//extension Request {
//    func render<ViewModel>(page: Page<ViewModel>) -> View
//    where ViewModel: Encodable, ViewModel: Sendable {
//        
//    }
//}
//
//extension Page {
//    static var manifest: Page {
//        Page(.manifest) { _ in
//            ManifestModel(
//                name: Environment.webApp.appName,
//                startURL: Environment.webApp.startURL
//            )
//        }
//    }
//}
//
//extension ViewRenderer {
//    func render<ViewModel>(page: Page<ViewModel>, with model: ViewModel) async throws -> View where ViewModel: Encodable {
//        try await self.render(page.templateName, model).get()
//    }
//    
//    func render(page: Page<Never>) async throws -> View {
//        try await self.render(page.templateName).get()
//    }
//    
//    func render(template: Template<Never>) async throws -> View {
//        try await self.render(template.name).get()
//    }
//}
//
//struct Route {
//    private let path: [PathComponent]
//    
//    private let handler: @Sendable (Request) async throws -> Response
//    
//    init(path: [PathComponent], handler: @Sendable @escaping (Request) async throws -> Response) {
//        self.path = path
//        self.handler = handler
//    }
//    
//    // Conveneince init for Web routes with views
//    init<Model: Encodable>(path: [PathComponent], page: Page<Model>) {
//        self.init(path: path) { request in
//            try await page.render(request)
//        }
//    }
//}
