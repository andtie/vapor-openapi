//
// TestSingleValueDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

class TestSingleValueDecodingContainer: TestUnkeyedDecodingContainer, SingleValueDecodingContainer {
    override func decodeNil() -> Bool {
        delegate?.isSingleValueOptional = true
        return false
    }
}
