import Vapor

struct ImageURLPayload: Content {
    let url: String
    let alt: String?
}
