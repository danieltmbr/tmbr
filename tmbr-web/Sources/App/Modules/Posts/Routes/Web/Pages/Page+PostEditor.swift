import Core
import Foundation
import Vapor
import Fluent
import AuthKit
import TmbrCore

struct PostEditorViewModel: Encodable, Sendable {

    private let id: Int?

    private let pageTitle: String?

    private let title: String

    private let body: String

    private let language: String

    private let state: Post.State

    private let submit: Form.Submit

    let _csrf: String?

    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String?,
        title: String = "",
        body: String = "",
        language: Language = .en,
        state: Post.State = .draft,
        submit: Form.Submit,
        error: String? = nil,
        csrf: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.title = title
        self.body = body
        self.language = language.rawValue
        self.state = state
        self.submit = submit
        self.error = error
        self._csrf = csrf
    }

    init(post: Post, csrf: String?) throws {
        let id = try post.requireID()
        self.init(
            id: id,
            pageTitle: "Edit '\(post.title)'",
            title: post.title,
            body: post.content,
            language: post.language,
            state: post.state,
            submit: Form.Submit(
                action: "/posts/\(id)",
                label: "Save"
            ),
            csrf: csrf
        )
    }
}

extension Template where Model == PostEditorViewModel {
    static let postEditor = Template(name: "Posts/post-editor")
}

extension Page {
    static var createPost: Self {
        Page(template: .postEditor) { req in
            try await req.permissions.posts.create()
            let submit = Form.Submit(
                action: "/posts",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return PostEditorViewModel(pageTitle: "New post", submit: submit, csrf: csrf)
        }
    }

    static var editPost: Self {
        Page(template: .postEditor) { req in
            guard let postID = req.parameters.get("postID", as: Int.self) else {
                throw Abort(.badRequest, reason: "Post ID is incorrect or missing.")
            }
            let post = try await req.commands.posts.fetch(postID, for: .write)
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return try PostEditorViewModel(post: post, csrf: csrf)
        }
    }
}
