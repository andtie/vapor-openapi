//
// TestContentDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor

public class TestContentDecoder: ContentDecoder {

    let configuration: Configuration
    weak var delegate: SchemaObjectDelegate?

    public init(_ configuration: Configuration, delegate: SchemaObjectDelegate?) {
        self.configuration = configuration
        self.delegate = delegate
    }

    public var result: (TestDecoder, Any.Type)?

    public func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        result = (TestDecoder(configuration, delegate: delegate), decodable)
        return try decodable.init(from: result!.0)
    }
}