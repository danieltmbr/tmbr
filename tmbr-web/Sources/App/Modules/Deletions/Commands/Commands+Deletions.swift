import Foundation
import Core

extension Commands {
    var deletions: Commands.Deletions.Type { Commands.Deletions.self }
}

extension Commands {
    struct Deletions: CommandCollection, Sendable {

        let list: CommandFactory<Date?, [Deletion]>

        init(list: CommandFactory<Date?, [Deletion]> = .listDeletions) {
            self.list = list
        }
    }
}
