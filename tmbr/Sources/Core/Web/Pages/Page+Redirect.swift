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
        
        fileprivate static let sessionKey: String = "redirect.return"
        
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
            request.redirectReturnDestination = self.return?(request)
            return request.redirect(to: destination, redirectType: kind)
        }
    }
    
    public func map(error map: @escaping @Sendable (Error) async throws -> Redirect) -> Page {
        self.catch { error, _ in try await map(error) }
    }
    
    public func redirect<E: Error & Equatable>(error: E, to redirect: Redirect) -> Page {
        self.map { e in
            if (e as? E) == error {
                return redirect
            } else {
                throw e
            }
        }
    }
    
    public func redirect(
        _ status: HTTPResponseStatus,
        destination: String,
        kind: Vapor.Redirect = .normal,
        return returnDestiantion: Redirect.ReturnDestination? = nil
    ) -> Page {
        self.catch { error, _ in
            guard let e = error as? Abort, e.status == status else {
                throw error
            }
            return Redirect(
                destination: destination,
                kind: kind,
                return: returnDestiantion
            )
        }
    }
}

extension Request {
    public var redirectReturnDestination: String? {
        get { session.data[Page.Redirect.sessionKey] }
        set { session.data[Page.Redirect.sessionKey] = newValue }
    }
}
