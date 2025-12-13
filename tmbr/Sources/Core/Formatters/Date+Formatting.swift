import Foundation

public extension Date {
    func formatted(_ format: DateFormat) -> String {
        format(date: self)
    }
}

public struct DateFormat: Sendable {

    typealias Formatting = @Sendable (Date) -> String
    
    private let format: Formatting
    
    init(format: @escaping Formatting) {
        self.format = format
    }
    
    public func callAsFunction(date: Date) -> String {
        format(date)
    }
    
    public static let publishDate = Self { date in
#if os(Linux)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
#else
        return date.formatted(
            date: .complete,
            time: .omitted
        )
#endif
    }
    
    public static let releaseDate = Self { date in
#if os(Linux)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
#else
        return date.formatted(
            date: .long,
            time: .omitted
        )
#endif
    }
    
    public static let rfc822 = Self { date in
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return dateFormatter.string(from: date)
    }
}
