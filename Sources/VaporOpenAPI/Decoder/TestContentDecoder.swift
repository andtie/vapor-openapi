//
// TestContentDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor

class TestContentDecoder: ContentDecoder {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    var result: (TestDecoder, Any.Type)?

    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        result = (TestDecoder(configuration), decodable)
        return try decodable.init(from: result!.0)
    }
}
