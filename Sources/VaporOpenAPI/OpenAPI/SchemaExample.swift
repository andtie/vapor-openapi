//
// SchemaExample.swift
//
// Created by Andreas in 2020
//

import Foundation
import Vapor

struct SchemaExample {

    let data: Data
    let schema: SchemaObject

    init(data: Data, for schema: SchemaObject) {
        self.data = data
        self.schema = schema
    }

    init?<T: Codable>(example: T, for schema: SchemaObject) {
        guard let encoder = try? ContentConfiguration.global.requireEncoder(for: .json)
        else { return nil }
        var headers = HTTPHeaders()
        var byteBuffer = ByteBuffer()
        try? encoder.encode(example, to: &byteBuffer, headers: &headers)
        guard let data = byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
        else { return nil }
        self.data = data
        self.schema = schema
    }

    func value<T: Decodable>(for type: T.Type) throws -> T {
        try ExportOpenAPI.previousBodyDecoder!.decode(T.self, from: .init(data: data), headers: .init())
    }
}
