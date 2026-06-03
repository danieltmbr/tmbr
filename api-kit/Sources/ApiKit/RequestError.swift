import Foundation

public enum RequestError: Error {
    case httpError(statusCode: Int, data: Data)
}
