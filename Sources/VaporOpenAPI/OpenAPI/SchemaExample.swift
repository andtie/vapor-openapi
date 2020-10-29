//
// SchemaExample.swift
//
// Created by Andreas in 2020
//

import Foundation
import Vapor

public struct SchemaExample {

    public let schema: SchemaObject

    public init(data: Data, for schema: SchemaObject) {
        self.data = { _, _ in data }
        self.schema = schema
    }

    public init<T: Codable>(example: T, for schema: SchemaObject) {
        self.schema = schema
        self.data = { Self.data(example: example, configuration: $0, location: $1) }
    }

    let data: (Configuration, Location) -> Data?

    enum Location {
        case header, body, path
    }

    enum SchemaExampleError: Error {
        case couldNotCreateData
    }

    static func data<T: Codable>(example: T, configuration: Configuration, location: Location) -> Data? {
        let contentConfig = configuration.contentConfiguration
        switch location {
        case .header, .body:
            guard let encoder = try? contentConfig.requireEncoder(for: .json) else { return nil }
            var headers = HTTPHeaders()
            var byteBuffer = ByteBuffer()
            try? encoder.encode(example, to: &byteBuffer, headers: &headers)
            return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
        case .path:
            guard let encoder = try? contentConfig.requireURLEncoder() else { return nil }
            var uri = URI()
            try? encoder.encode(example, to: &uri)
            return uri.query.map { Data($0.utf8) }
        }
    }

    func value<T: Decodable>(for type: T.Type, configuration: Configuration, location: Location) throws -> T {
        guard let data = self.data(configuration, location)
        else { throw SchemaExampleError.couldNotCreateData }
        return try configuration.bodyDecoder.decode(T.self, from: .init(data: data), headers: .init())
    }
}
