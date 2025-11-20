import Vapor
import Fluent
import AuthKit
import Core

struct PostsWebController: RouteCollection {
    
    private enum EditorMode {
        case create
        case update(postID: Int)
    }
        
    func boot(routes: RoutesBuilder) throws {
        routes.get(page: .posts)
        routes.get("post", ":postID", page: .post)

        routes.get("drafts", page: .drafts)

        routes.get("post", "new", page: .createPost)
        routes.post("post", use: createPost)

        routes.get("post", ":postID", "edit", page: .editPost)
        routes.post("post", ":postID", use: updatePost)

        routes.post("post", "preview", page: .postPreview)
    }

    @Sendable
    private func createPost(_ req: Request) async throws -> Response {
        try await handleEditorSubmission(req, mode: .create)
    }

    @Sendable
    private func updatePost(_ req: Request) async throws -> Response {
        guard let postID = req.parameters.get("postID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Missing post ID")
        }
        return try await handleEditorSubmission(req, mode: .update(postID: postID))
    }

    private func handleEditorSubmission(_ req: Request, mode: EditorMode) async throws -> Response {
        do {
            let payload = try req.content.decode(PostPayload.self)
            guard let submittedCSRF = payload._csrf, submittedCSRF == req.session.data["csrf.editor"] else {
                throw Abort(.forbidden, reason: "Invalid form token. Please reload the editor and try again.")
            }
            let post = switch mode {
            case .create:
                try await req.commands.posts.create(payload)
            case .update(let postID):
                try await req.commands.posts.edit(payload.edit(id: postID))
            }
            req.session.data["csrf.editor"] = nil
            return req.redirect(to: "/post/\(post.id!)")
        } catch {
            // TODO: Clean this up a bit
            let submitted = (try? req.content.decode(PostPayload.self)) ?? PostPayload()
            let submit: Form.Submit
            let postID: PostID?
            let pageTitle: String
            
            switch mode {
            case .create:
                postID = nil
                submit = Form.Submit(action: "/post", label: "Save", method: .POST)
                pageTitle = "New post"
            case .update(let id):
                postID = id
                submit = Form.Submit(action: "/post/\(id)", label: "Save", method: .POST)
                pageTitle = "Edit '\(submitted.title)'"
            }
            
            let model = PostEditorViewModel(
                id: postID,
                pageTitle: pageTitle,
                title: submitted.title,
                body: submitted.body ?? "",
                state: submitted.state,
                submit: submit,
                error: editorErrorHTML(for: error, on: req),
                csrf: UUID().uuidString
            )
            
            let view = try await Template.postEditor.render(model, with: req.view)
            let response = try await view.encodeResponse(for: req)
            req.session.data["csrf.editor"] = model._csrf
            return response
        }
    }

    private func editorErrorHTML(for error: Error, on req: Request) -> String {
        if let abort = error as? AbortError {
            switch abort.status {
            case .unauthorized:
                return "Please <a href=\"/signin?return=\(req.url.path)\">sign in</a> and try again."
            case .forbidden:
                return "You don’t have permission to edit this post."
            case .notFound:
                return "This post doesn’t exist or isn’t available."
            case .badRequest:
                return abort.reason.isEmpty ? "Please check your input and try again." : abort.reason
            default:
                break
            }
        }
        if error is ValidationsError {
            return "Title is required."
        }
        return "Something went wrong. Please try again."
    }
}

