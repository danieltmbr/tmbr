import Vapor
import Fluent

struct NotificationsWebController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.get("notifications", "panel", use: panel)
    }

    private func panel(req: Request) async throws -> View {
        let categories = try await CatalogueCategory.query(on: req.db)
            .filter(\.$kind ~~ [.collection, .catalogue])
            .all()

        // Collections (e.g. music) and top-level catalogue items (book, movie, podcast)
        // are offered as Note sub-categories.
        let noteChildren: [PanelOption] = categories
            .filter { $0.kind == .collection || ($0.kind == .catalogue && $0.parentSlug == nil) }
            .map { PanelOption(value: "note:\($0.slug)", label: $0.name, hasChildren: false, children: []) }

        let options: [PanelOption] = [
            PanelOption(value: "post", label: "Posts", hasChildren: false, children: []),
            PanelOption(value: "note", label: "Notes", hasChildren: true, children: noteChildren),
        ]
        return try await req.view.render("Panels/notification-panel", PanelContext(options: options))
    }
}

private struct PanelOption: Content {
    let value: String
    let label: String
    let hasChildren: Bool
    let children: [PanelOption]
}

private struct PanelContext: Content {
    let options: [PanelOption]
}
