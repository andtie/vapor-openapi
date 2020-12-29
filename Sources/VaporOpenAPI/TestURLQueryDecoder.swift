//
// TestURLQueryDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor
import OpenAPI
import OpenAPIDecoder

public class TestURLQueryDecoder: URLQueryDecoder {

    let configuration: CoderConfig
    weak var delegate: SchemaObjectDelegate?

    public init(_ configuration: CoderConfig, delegate: SchemaObjectDelegate?) {
        self.configuration = configuration
        self.delegate = delegate
    }

    public var decoders: [TestDecoder] = []

    public func decode<D>(_ decodable: D.Type, from url: URI) throws -> D where D: Decodable {
        let decoder = TestDecoder(configuration, delegate: delegate)
        decoders.append(decoder)
        return try decodable.init(from: decoder)
    }
}
