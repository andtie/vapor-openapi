//
// Faker.swift
//
// Created by Andreas in 2020
//

import Foundation

public final class Faker {
    let schemaObject: SchemaObject
    let configuration: Configuration
    let arrayCount = 10
    var rng: IteratingRandomNumberGenerator

    public init(schemaObject: SchemaObject, configuration: Configuration = .default, rng: IteratingRandomNumberGenerator = .init()) {
        self.schemaObject = schemaObject
        self.configuration = configuration
        self.rng = rng
    }

    public enum FakerError: Error {
        case noProperties
        case itemsEmpty
    }

    public func generateJSON() throws -> Data {
        let value = try generateJSON(hint: nil)
        #if os(Linux)
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        #else
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        #endif
        return try JSONSerialization.data(withJSONObject: value, options: options)
    }

    private func generateJSON(hint: String?) throws -> Any {
        if let values = schemaObject.enum, let first = values.first {
            return (values.randomElement(using: &rng) ?? first).value
        }
        switch schemaObject.type {
        case .object:
            if let properties = schemaObject.properties {
                let mapped = try properties.sorted(by: { $0.0 < $1.0 }).map { key, value in
                    try (key, Faker(schemaObject: value, configuration: configuration, rng: rng)
                            .generateJSON(hint: key))
                }
                return Dictionary(mapped, uniquingKeysWith: { x, y in x })
            } else if let valueType = schemaObject.additionalProperties {
                let mapped = try (0..<arrayCount).map { index -> (String, Any) in
                    let key = "\(hint ?? "")-\(index)"
                    let value = try Faker(schemaObject: valueType, configuration: configuration, rng: rng)
                        .generateJSON(hint: hint)
                    return (key, value)
                }
                return Dictionary(mapped, uniquingKeysWith: { x, y in x })
            } else {
                throw FakerError.noProperties
            }
        case .array:
            guard let itemType = schemaObject.items else {
                throw FakerError.itemsEmpty
            }
            return try (0..<arrayCount).map { index in
                try Faker(schemaObject: itemType, configuration: configuration, rng: rng)
                    .generateJSON(hint: (hint ?? "") + "_\(index)")
            }
        case .integer:
            switch schemaObject.format {
            case .int32:
                return abs(Int32.random(using: &rng))
            case .int64:
                return abs(Int64.random(using: &rng))
            default:
                return abs(Int.random(using: &rng))
            }
        case .number:
            switch schemaObject.format {
            case .float:
                return Float.random(in: 0...100, using: &rng)
            default:
                return Double.random(in: 0...100, using: &rng)
            }
        case .boolean:
            return Bool.random(using: &rng)
        case .string:
            switch schemaObject.format {
            case .byte:
                return "iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAASFBMVEX/AAD/fX3/jIz/m5v/q6v/uLj/trb/qan/ior/gYH/2dn/dHT/eHj//Pz/8/P/5OT/z8//yMj/srL/kZH/lZX/oKD/rq7/pKT5lJt8AAABl0lEQVR4nO3dS24CMRAG4TYzw2MgDwiQ+980WWQRZROE1GqVXZ8v8NfSkiXHy+vb+n4+L8tymed5N/342Py2b087bP51nR5wmx9wX/7arnGJvh1jrp6QrA1Q+Fk9IVmLqXpCMgv5LOSzkM9CPgv5Rii8Vk9I1mJTPSGZhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIN0LhvnpCsvZ9+mYhn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvK1OFRPSDbCi6H+X31ZSGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8IxT2/8+MhXQW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwjFN6qJyRrsauekKzFXD0hmYV8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8Le7VE5K12FZPSNZiqZ6QzEI+C/ks5LOQz0I+C/ks5BuhsPcb8CnWY+vZafkCI00HxRaYb6EAAAAASUVORK5CYII="
            case .date, .dateTime:
                let date = Date(timeIntervalSinceReferenceDate: Double.random(in: 0...1e9, using: &rng))
                let data = configuration.encode(example: date)!
                return String(data: data, encoding: .utf8)!
                    .trimmingCharacters(in: .init(charactersIn: "\""))
            case .email:
                return "test-\(rng.nextValue())@example.com"
            case .uuid:
                return String(format: "00000000-0000-0000-0000-%012d", rng.nextValue())
            default:
                return string(with: hint?.componentsSeparatedByCamelCase() ?? [])
            }
        }
    }

    private func string(with hints: [String]) -> Any {
        if hints.contains("id") || hints.contains("identifier") || hints.contains("identification") {
            return String(rng.nextValue())
        }
        if hints.contains("name") {
            let name: String
            if hints.contains("first") || hints.contains("given") {
                name = elements(from: firstNames, maxCount: 2).joined(separator: " ")
            } else if hints.contains("last") {
                name = elements(from: lastNames, maxCount: 2).joined(separator: "-")
            } else if hints.contains("full") {
                name = elements(from: firstNames, maxCount: 1).joined(separator: " ")
                    + elements(from: lastNames, maxCount: 2).joined(separator: "-")
            } else {
                name = elements(from: genericNames, maxCount: 2).joined(separator: " ")
            }
            return name
        }
        if hints.contains("phone") {
            return String(format: "+49 123 %07d", UInt.random(in: 0...9999999, using: &rng))
        }
        if hints.contains("number") {
            return String(UInt.random(using: &rng))
        }
        if hints.contains("url") {
            if hints.contains("image") || hints.contains("picture") {
                return "https://picsum.photos/200"
            } else {
                return "https://google.com?query=\(Int.random(using: &rng))"
            }
        }
        return "test-\(hints.joined(separator: "-"))"
    }

    private let firstNames = ["Frank", "Walter", "Maria", "Heribert", "Gustav", "Joe", "Danielle", "Lisa"]
    private let lastNames = ["Miller", "Doe", "Simpson", "Smith", "McDonald", "Singh", "Erikson", "López"]
    private let genericNames = ["Boulet", "Fulgor", "Quemas", "Prende", "Mojado", "Gass", "Brise", "Fumant"]

    private func elements(from strings: [String], maxCount: UInt) -> [String] {
        let length = UInt.random(in: 1...max(maxCount, 1), using: &rng)
        return (1...length)
            .compactMap { _ in strings.randomElement(using: &rng) }
    }
}
