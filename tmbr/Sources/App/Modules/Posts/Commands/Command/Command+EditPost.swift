import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit

extension Core.Command where Self == PlainCommand<Post, Post> {
    
    static var editPost: Self {
        PlainCommand { _ in
            fatalError()
        }
    }
}

extension CommandFactory<Post, Post> {
    
    static var editPost: Self {
        CommandFactory { request in
            .editPost
            .logged(name: "Edit Post", logger: request.logger)
        }
    }
}
