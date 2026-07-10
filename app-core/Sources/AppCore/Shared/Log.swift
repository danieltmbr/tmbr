import OSLog

extension Logger {
    static let blog = Logger(subsystem: "me.tmbr", category: "blog")
    static let catalogue = Logger(subsystem: "me.tmbr", category: "catalogue")
    static let quotes = Logger(subsystem: "me.tmbr", category: "quotes")
}
