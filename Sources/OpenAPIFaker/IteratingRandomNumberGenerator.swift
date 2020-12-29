//
// IteratingRandomNumberGenerator.swift
//
// Created by Andreas in 2020
//

import Foundation

public class IteratingRandomNumberGenerator: RandomNumberGenerator {
    var value: UInt64 = 1

    public init() {}

    public func nextValue() -> UInt64 {
        defer { value += 1 }
        return value
    }

    public func next() -> UInt64 {
        deterministicHash(nextValue())
    }

    /// in constrast to `hashValue`, this function is consistent over several runs
    func deterministicHash(_ value: UInt64) -> UInt64 {
        var x = value
        x = (x ^ (x >> 30)) &* 0xbf58476d1ce4e5b9
        x = (x ^ (x >> 27)) &* 0x94d049bb133111eb
        return x ^ (x >> 31)
    }
}
