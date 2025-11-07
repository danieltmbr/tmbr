import Vapor

public struct PermissionResolver<Input> {
    
    private let permission: Permission<Input>
    
    private let request: Request
    
    init(request: Request, permission: Permission<Input>) {
        self.request = request
        self.permission = permission
    }
    
    @discardableResult
    public func callAsFunction(_ input: Input) throws(PermissionError) -> Permission<Input>.Grant {
        try permission.verify(input, on: request)
    }
    
    @discardableResult
    public func callAsFunction() throws(PermissionError) -> Permission<Input>.Grant
    where Input == Void {
        try callAsFunction(())
    }
}
