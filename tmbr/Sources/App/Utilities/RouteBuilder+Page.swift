import Vapor

extension RoutesBuilder {
    @discardableResult
    @preconcurrency
    func get<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.GET, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func get<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.GET, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func post<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.POST, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func post<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.POST, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func patch<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PATCH, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func patch<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PATCH, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func put<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PUT, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func put<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.PUT, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func delete<Model>(
        _ path: PathComponent...,
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.DELETE, path, use: page.render)
    }
    
    @discardableResult
    @preconcurrency
    func delete<Model>(
        _ path: [PathComponent],
        page: Page<Model>
    ) -> Route
    where Model: Encodable & Sendable
    {
        return self.on(.DELETE, path, use: page.render)
    }
}

