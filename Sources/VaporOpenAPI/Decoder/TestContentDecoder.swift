//
// TestContentDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor

class TestContentDecoder: ContentDecoder {

    let schemaExamples: [SchemaExample]

    init(_ schemaExamples: [SchemaExample]) {
        self.schemaExamples = schemaExamples
    }

    var result: (TestDecoder, Any.Type)?

    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        result = (TestDecoder(schemaExamples), decodable)
        return try decodable.init(from: result!.0)
    }
}
