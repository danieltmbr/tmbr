import Vapor

public extension RoutesBuilder {
    @discardableResult
    @preconcurrency
    func get<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.GET, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func get<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.GET, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func post<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.POST, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func post<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.POST, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func patch<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PATCH, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func patch<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PATCH, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func put<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PUT, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func put<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PUT, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func delete<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.DELETE, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func delete<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.DELETE, path, use: page.response)
    }
    
    @discardableResult
    @preconcurrency
    func on(
        _ method: HTTPMethod,
        _ path: PathComponent...,
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @Sendable @escaping (Request) async throws -> AsyncResponseEncodable
    ) -> Route {
        return self.on(method, path, body: body, use: { request in
            return try await closure(request)
        })
    }
    
    @discardableResult
    @preconcurrency
    func on(
        _ method: HTTPMethod,
        _ path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        use closure: @Sendable @escaping (Request) async throws -> AsyncResponseEncodable
    ) -> Route {
        let responder = AsyncBasicResponder { request in
            if case .collect(let max) = body, request.body.data == nil {
                _ = try await request.eventLoop.flatSubmit {
                    request.body.collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value)
                }.get()
                
            }
            return try await closure(request).encodeResponse(for: request)
        }
        let route = Route(
            method: method,
            path: path,
            responder: responder,
            requestType: Request.self,
            responseType: Response.self
        )
        self.add(route)
        return route
    }

}

