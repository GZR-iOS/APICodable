//
//  NWUrlSingleValueEncodingContainer.swift
//
//  Created by DươngPQ on 04/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

struct NWKeyPathSingleValueEncodingContainer: SingleValueEncodingContainer {

    var codingPath: [CodingKey] {
        return encoder.codingPath
    }
    weak var encoder: NWKeyPathEncoder!
    private let nestedEncoder: NWKeyPathEncoder

    init(owner: NWKeyPathEncoder) {
        encoder = owner
        nestedEncoder = NWKeyPathEncoder(parent: owner)
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        nestedEncoder.codingPath = codingPath
        if (try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)) {
            nestedEncoder.keyPath = encoder.keyPath
            try value.encode(to: nestedEncoder)
        }
    }

    mutating func encode(_ value: String) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encodeNil() throws {
        _ = try encoder.delegate.encodeNil(keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Bool) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Int) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Int8) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Int16) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Int32) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Int64) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: UInt) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: UInt8) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: UInt16) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: UInt32) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: UInt64) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Float) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encode(_ value: Double) throws {
        try encoder.delegate.encode(value: value, keyPath: encoder.keyPath)
    }

    mutating func encodeIfPresent(_ value: Bool?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Int?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Int8?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Int16?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Int32?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Int64?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: UInt?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: UInt8?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: UInt16?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: UInt32?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: UInt64?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Float?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: Double?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent(_ value: String?) throws {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

    mutating func encodeIfPresent<T>(_ value: T?) throws where T : Encodable {
        if let val = value {
            try encode(val)
        } else {
            try encodeNil()
        }
    }

}
