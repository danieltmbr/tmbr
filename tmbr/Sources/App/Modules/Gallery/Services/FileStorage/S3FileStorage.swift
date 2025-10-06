import Foundation
import Vapor
import SotoS3

actor S3FileStorage: FileStorage {
    
    private let bucket: String
    
    private let s3: S3
    
    init(bucket: String, s3: S3) {
        self.bucket = bucket
        self.s3 = s3
    }
    
    init(
        bucket: String,
        region: Region,
        client: AWSClient = .init()
    ) {
        self.init(
            bucket: bucket,
            s3: S3(client: client, region: region)
        )
    }
    
    deinit {
        try? s3.client.syncShutdown()
    }
    
    func delete(name: String) async throws {
        let request = S3.DeleteObjectRequest(
            bucket: bucket,
            key: name
        )
        _ = try await s3.deleteObject(request)
    }
    
    func file(named name: String) async throws -> Data {
        let request = S3.GetObjectRequest(bucket: bucket, key: name)
        let object = try await s3.getObject(request)
        let buffer = try await object.body.collect(upTo: object.body.length ?? 0)
        return Data(buffer: buffer)
    }
    
    func store(
        data: Data,
        contentType: String,
        name: String
    ) async throws {
        let request = S3.PutObjectRequest(
            body: AWSHTTPBody(buffer: ByteBuffer(data: data)),
            bucket: bucket,
            contentType: contentType,
            key: name
        )
        _ = try await s3.putObject(request)
    }
}
