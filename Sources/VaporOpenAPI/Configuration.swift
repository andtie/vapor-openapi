//
// Configuration.swift
//
// Created by Andreas in 2020
//

import OpenAPI
import OpenAPIDecoder
import Vapor

public struct Configuration {
    public var preProcessor: (Request) -> Void
    public var postProcessor: (inout OpenAPI) -> Void
    public var coderConfig: CoderConfig

    public enum ConfigError: Error {
        case noData, noQuery
    }

    public static var `default` = Configuration(
        preProcessor: { _ in },
        postProcessor: { _ in },
        coderConfig: CoderConfig(coder: ContentConfiguration.global)
    )
}

extension ContentConfiguration: APICoderProtocol {
    public func encodeAsBody<T: Encodable>(example: T) -> Data? {
        var headers = HTTPHeaders()
        var byteBuffer = ByteBuffer()
        let encoder = try? requireEncoder(for: .json)
        try? encoder?.encode(example, to: &byteBuffer, headers: &headers)
        return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
    }

    public func encodeAsURL<T: Encodable>(example: T) -> Data? {
        var uri = URI()
        let encoder = try? requireURLEncoder()
        try? encoder?.encode(example, to: &uri)
        return uri.query.map { Data($0.utf8) }
    }

    public func decodeAsBody<T: Decodable>(data: Data) throws -> T {
        let decoder = try requireDecoder(for: .json)
        return try decoder.decode(T.self, from: .init(data: data), headers: .init())
    }

    public static var saved: ContentConfiguration?

    public static var current: ContentConfiguration {
        .saved ?? .global
    }
}
