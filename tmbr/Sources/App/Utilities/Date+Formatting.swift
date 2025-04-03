import Foundation

extension Date {
    func formatted(_ format: DateFormat) -> String {
        format(date: self)
    }
}

struct DateFormat: Sendable {

    typealias Formatting = @Sendable (Date) -> String
    
    private let format: Formatting
    
    init(format: @escaping Formatting) {
        self.format = format
    }
    
    func callAsFunction(date: Date) -> String {
        format(date)
    }
    
    static let publishDate = Self { date in
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
}
