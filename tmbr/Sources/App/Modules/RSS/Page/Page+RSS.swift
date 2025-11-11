import Vapor
import Core
import Fluent

extension Template where Model == RSSViewModel {
    static let rss = Template(name: "rss")
}

extension Page {
    static var rss: Self {
        Page { request in
            let posts = try await Post.query(on: request.db)
                .filter(\.$state == .published)
                .sort(\.$createdAt, .descending)
                .all()
            let model = RSSViewModel(
                title: "tmbr",
                url: "https://tmbr.me",
                description: "Dani's Blog",
                posts: posts.compactMap {
                    guard let id = $0.id else { return nil }
                    return RSSViewModel.Post(
                        title: $0.title,
                        url: "https://tmbr.me/post/\(id)",
                        publishDate: $0.createdAt.formatted(.rfc822)
                    )
                }
            )
            
            let view = try await Template.rss.render(model, with: request.view)
            
            var headers = HTTPHeaders()
            headers.replaceOrAdd(
                name: .contentType,
                value: "application/rss+xml; charset=utf-8"
            )
            return Response(
                status: .ok,
                headers: headers,
                body: Response.Body(buffer: view.data)
            )
        }
    }
}
