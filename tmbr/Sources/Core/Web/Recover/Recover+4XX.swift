import Foundation
import Vapor

extension Page.Recover {
    
    public static var unathorized: Self {
        Page.Recover(
            status: .unauthorized,
            response: Page.Redirect(destination: "/signin", return: .origin)
        )
    }
    
    public static var fourhundreds: Self {
        Page.Recover { abort in
            guard 400..<500 ~= abort.status.code else { throw abort }
            return ErrorViewModel(abort: abort)
        }
    }
}
