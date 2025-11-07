import Foundation
import Vapor

extension Page {
    
    public struct Redirect: AsyncResponseEncodable {
        
        public struct ReturnDestination: ExpressibleByStringLiteral {
            private let path: (Request) -> String
            
            private init(path: @escaping (Request) -> String) {
                self.path = path
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.init { _ in value }
            }
            
            public static let origin = Self { $0.url.string }
            
            fileprivate func callAsFunction(_ request: Request) -> String {
                path(request)
            }
        }
        
        static let sessionKey: String = "redirect.return"
        
        fileprivate let destination: String
        
        fileprivate let kind: Vapor.Redirect
        
        fileprivate let `return`: ReturnDestination?
        
        public init(
            destination: String,
            kind: Vapor.Redirect = .normal,
            return returnDestiantion: ReturnDestination? = nil
        ) {
            self.destination = destination
            self.kind = kind
            self.return = returnDestiantion
        }
        
        public func encodeResponse(for request: Request) async throws -> Response {
            let dest = URLComponents(
                destination: destination,
                return: self.return?(request)
            )
            return request.redirect(
                to: dest?.string ?? destination,
                redirectType: kind
            )
        }
    }
    
    public func redirect(error map: @escaping @Sendable (Error) async throws -> Redirect) -> Page {
        self.recover { error, _ in
            try await map(error)
        }
    }
    
    public func redirect<E: Error & Equatable>(error: E, to redirect: Redirect) -> Page {
        self.redirect {
            guard ($0 as? E) == error else { throw $0 }
            return redirect
        }
    }
    
    public func redirect(
        error status: HTTPResponseStatus,
        destination: String,
        kind: Vapor.Redirect = .normal,
        return returnDestiantion: Redirect.ReturnDestination? = nil
    ) -> Page {
        let redirect = Redirect(
            destination: destination,
            kind: kind,
            return: returnDestiantion
        )
        return self.recover(error: status, response: redirect)
    }
}

private extension URLComponents {
    init?(destination: String, return rd: String?) {
        self.init(string: destination)
        if let rd {
            let item = URLQueryItem.redirectReturn(path: rd)
            if var queryItems {
                queryItems.append(item)
                self.queryItems = queryItems
            } else {
                queryItems = [item]
            }
        }
    }
}
