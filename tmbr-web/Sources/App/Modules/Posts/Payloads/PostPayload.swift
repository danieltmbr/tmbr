import Vapor
import Foundation
import TmbrCore

struct PostPayload: Decodable, Sendable {

    let title: String

    let body: String?

    let language: Language

    let state: Post.State

    let _csrf: String?

    init(
        title: String = "",
        body: String? = nil,
        language: Language = .en,
        state: Post.State = .draft,
        _csrf: String? = nil
    ) {
        self.title = title
        self.body = body
        self.language = language
        self.state = state
        self._csrf = _csrf
    }
}

extension PostPayload {
    // TODO: This could also follow functional patterns like Permissions and Commands
    func validate() throws {
        guard !title.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "Title is required")
        }
        guard state == .published || !body.trimmed.isEmpty else {
            throw Abort(.badRequest, reason: "Sorry, can't publish an empty post.")
        }
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Optional<String> {
    var trimmed: String {
        self?.trimmed ?? ""
    }
}
