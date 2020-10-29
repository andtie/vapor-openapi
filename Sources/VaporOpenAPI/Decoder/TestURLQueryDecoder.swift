//
// TestURLQueryDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor

class TestURLQueryDecoder: URLQueryDecoder {

    let schemaExamples: [SchemaExample]

    init(_ schemaExamples: [SchemaExample]) {
        self.schemaExamples = schemaExamples
    }

    var decoders: [TestDecoder] = []

    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D where D: Decodable {
        let decoder = TestDecoder(schemaExamples)
        decoders.append(decoder)
        return try decodable.init(from: decoder)
    }
}
