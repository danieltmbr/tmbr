import Foundation
import Vapor
import Core
import CoreWeb

extension Page.Recover {
    
    static var aborts: Self {
        .unathorized
            .combine(with: .fourhundreds)
            .combine(with: .fivehundreds)
    }
    
    init(
        abort map: @escaping @Sendable (Abort) throws -> ErrorViewModel = ErrorViewModel.init(abort:)
    ) {
        self.init { error in
            guard let abort = error as? Abort else { throw error }
            return try map(abort)
        }
    }
}
