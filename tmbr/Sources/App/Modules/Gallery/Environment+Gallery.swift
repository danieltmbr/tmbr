import Vapor

extension Environment {
    struct Gallery: Sendable {
        /// AWS S3 bucket name
        let bucket = Environment.get("AWS_S3_BUCKET")!
        
        /// Region code of the AWS service
        let region = Environment.get("AWS_S3_REGION")!
    }

    /// Evironment values for Image Gallery module
    static let gallery = Gallery()
}
