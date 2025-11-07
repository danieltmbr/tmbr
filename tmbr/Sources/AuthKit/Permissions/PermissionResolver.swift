import Vapor

public struct PermissionResolver<Input> {
    
    private let permission: Permission<Input>
    
    private let request: Request
    
    init(request: Request, permission: Permission<Input>) {
        self.request = request
        self.permission = permission
    }
    
    @discardableResult
    public func callAsFunction(_ input: Input) throws -> Permission<Input>.AuthenticatedUser {
        try permission.grant(input, on: request)
    }
    
    @discardableResult
    public func callAsFunction() throws -> Permission<Input>.AuthenticatedUser
    where Input == Void {
        try callAsFunction(())
    }
}
