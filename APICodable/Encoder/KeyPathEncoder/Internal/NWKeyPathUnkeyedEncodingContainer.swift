//
//  NWUrlUnkeyedEncodingContainer.swift
//
//  Created by DươngPQ on 04/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

struct NWKeyPathUnkeyedEncodingContainer: UnkeyedEncodingContainer {

    weak var encoder: NWKeyPathEncoder!
    var count = 0
    var codingPath: [CodingKey] {
        return encoder.codingPath
    }
    private let nestedEncoder: NWKeyPathEncoder

    private var keyPath: NWKeyPath {
        return encoder.keyPath + [NWKeyPathType.unkey(UInt(count))]
    }

    init(owner: NWKeyPathEncoder) {
        encoder = owner
        nestedEncoder = NWKeyPathEncoder(parent: owner)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return nestedEncoder.container(keyedBy: keyType)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return nestedEncoder.unkeyedContainer()
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        nestedEncoder.codingPath = codingPath
        let path = keyPath
        if (try encoder.delegate.encode(value: value, keyPath: path)) {
            nestedEncoder.keyPath = path
            try value.encode(to: nestedEncoder)
        }
        count += 1
    }

    mutating func encode(_ value: String) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encodeNil() throws {
        if (try encoder.delegate.encodeNil(keyPath: keyPath)) {
            count += 1
        }
    }

    mutating func encode(_ value: Bool) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Int) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Int8) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Int16) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Int32) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Int64) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: UInt) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: UInt8) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: UInt16) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: UInt32) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: UInt64) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Float) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
    }

    mutating func encode(_ value: Double) throws {
        try encoder.delegate.encode(value: value, keyPath: keyPath)
        count += 1
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
