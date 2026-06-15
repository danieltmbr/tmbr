import Foundation
import Core

extension Commands {
    var deletions: Commands.Deletions.Type { Commands.Deletions.self }
}

extension Commands {
    struct Deletions: CommandCollection, Sendable {

        let list: CommandFactory<ListDeletionsInput, [Deletion]>

        init(list: CommandFactory<ListDeletionsInput, [Deletion]> = .listDeletions) {
            self.list = list
        }
    }
}
