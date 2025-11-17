import Foundation
import Vapor

extension Page.Recover {
    
    public static var fivehundreds: Self {
        Page.Recover { abort in
            guard 500..<600 ~= abort.status.code else { throw abort }
            return ErrorViewModel(
                title: "Congrats, you found a bug!",
                message: """
                Unfortunately, there is no prize money. Even worse, there is nothing you can do to resolve the issue.
                
                Rest assured it's logged in the system and I'll try to fix it in the future. 
                To avoid breaking promises, my SLA is Five Zeros. So I don't know when I'm going to fix it.

                You can help me out by either sending an [email](mailto:daniel@tmbr.me) or raising a [Issue on GitHub](https://github.com/danieltmbr/tmbr/issues/new/choose) with the details of what happened.
                
                Thanks, I hope you have a better day than my backend.
                """
            )
        }
    }
}
