import Vapor
import Core
import Foundation

extension Configuration where Self == CoreConfiguration {
    static var content: Self {
        CoreConfiguration { app in
            ContentConfiguration.global.use(
                decoder: .isoDateFormatFormDecoder,
                for: .urlEncodedForm
            )
        }
    }
}

private extension ContentDecoder where Self == URLEncodedFormDecoder {
    static var isoDateFormatFormDecoder:  URLEncodedFormDecoder {
        URLEncodedFormDecoder(configuration: .init(dateDecodingStrategy: .iso))
    }
}

private extension URLEncodedFormDecoder.Configuration.DateDecodingStrategy {
    static var iso: Self {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            guard let date = ISO8601DateFormatter.isoFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid ISO 8601 date: \(dateString)"
                )
            }
            return date
        }
    }
}

private extension ISO8601DateFormatter {
    static var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        return formatter
    }
}
