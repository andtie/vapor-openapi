//
// TestURLQueryDecoder.swift
//
// Created by Andreas in 2020
//

import Vapor

class TestURLQueryDecoder: URLQueryDecoder {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    var decoders: [TestDecoder] = []

    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D where D: Decodable {
        let decoder = TestDecoder(configuration)
        decoders.append(decoder)
        return try decodable.init(from: decoder)
    }
}
