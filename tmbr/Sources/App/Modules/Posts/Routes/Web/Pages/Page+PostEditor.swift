import Core
import Foundation
import Vapor
import Fluent
import AuthKit

struct PostEditorViewModel: Encodable, Sendable {
    
    private let id: Int?
    
    private let pageTitle: String?

    private let title: String
    
    private let body: String
    
    private let state: Post.State
    
    private let submit: Form.Submit

    let _csrf: String?
    
    private let error: String?

    init(
        id: Int? = nil,
        pageTitle: String?,
        title: String = "",
        body: String = "",
        state: Post.State = .draft,
        submit: Form.Submit,
        error: String? = nil,
        csrf: String? = nil
    ) {
        self.id = id
        self.pageTitle = pageTitle
        self.title = title
        self.body = body
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
            state: post.state,
            submit: Form.Submit(
                action: "/post/\(id)",
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
                action: "/post",
                label: "Save"
            )
            let csrf = UUID().uuidString
            req.session.data["csrf.editor"] = csrf
            return PostEditorViewModel(pageTitle: "New post", submit: submit, csrf: csrf)
        }
        .recover(.aborts)
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

