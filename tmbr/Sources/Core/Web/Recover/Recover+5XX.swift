import Foundation
import Vapor

extension Page.Recover {
    
    public static var fivehundreds: Self {
        Page.Recover { abort in
            guard 500..<600 ~= abort.status.code else { throw abort }
            return ErrorViewModel(
                title: "Congrats, you found a bug!",
                message: """
                Unfortunately, there is prize money for it and what even worse is, there is nothing you can do to resolve the issue instantly.
                
                Rest assured it's logged in the system and I'll try to fix it in the future. 
                To avoid breaking promises, I won't provide a time frame for when the fix will be shipped. 

                You can help me out by either sending an [email](mailto:daniel@tmbr.me) or raising a [Issue on GitHub](https://github.com/danieltmbr/tmbr/issues/new/choose) with the details of what happened.
                
                Thanks and have a better rest of the day.
                """
            )
        }
    }
}
