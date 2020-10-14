//
// TestSingleValueDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation

class TestSingleValueDecodingContainer: TestUnkeyedDecodingContainer, SingleValueDecodingContainer {
    override func decodeNil() -> Bool {
        true
    }
}
