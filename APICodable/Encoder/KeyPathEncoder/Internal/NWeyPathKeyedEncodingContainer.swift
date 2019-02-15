//
//  NWUrlKeyedEncodingContainer.swift
//
//  Created by DươngPQ on 04/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

struct NWKeyPathKeyedEncodingContainer<KeyType>: KeyedEncodingContainerProtocol where KeyType: CodingKey {

    typealias Key = KeyType

    weak var encoder: NWKeyPathEncoder!

    var codingPath: [CodingKey] {
        return encoder.codingPath
    }
    private let nestedEncoder: NWKeyPathEncoder

    init(owner: NWKeyPathEncoder) {
        encoder = owner
        nestedEncoder = NWKeyPathEncoder(parent: owner)
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: KeyType) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(NWKeyPathKeyedEncodingContainer<NestedKey>(owner: nestedEncoder))
    }

    mutating func nestedUnkeyedContainer(forKey key: KeyType) -> UnkeyedEncodingContainer {
        return NWKeyPathUnkeyedEncodingContainer(owner: nestedEncoder)
    }

    mutating func superEncoder() -> Encoder {
        return encoder
    }

    mutating func superEncoder(forKey key: KeyType) -> Encoder {
        return encoder
    }

    mutating func encode<T>(_ value: T, forKey key: KeyType) throws where T : Encodable {
        nestedEncoder.codingPath = codingPath + [key]
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        if (try encoder.delegate.encode(value: value, keyPath: keypath)) {
            nestedEncoder.keyPath = keypath
            try value.encode(to: nestedEncoder)
        }
    }

    mutating func encode(_ value: String, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encodeNil(forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        _ = try encoder.delegate.encodeNil(keyPath: keypath)
    }

    mutating func encode(_ value: Bool, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Int, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Int8, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Int16, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Int32, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Int64, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: UInt, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: UInt8, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: UInt16, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: UInt32, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: UInt64, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Float, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encode(_ value: Double, forKey key: KeyType) throws {
        let keypath = encoder.keyPath + [NWKeyPathType.key(key.stringValue)]
        try encoder.delegate.encode(value: value, keyPath: keypath)
    }

    mutating func encodeIfPresent(_ value: Bool?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int8?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int16?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int32?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Int64?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt8?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt16?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt32?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: UInt64?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Float?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: Double?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent(_ value: String?, forKey key: KeyType) throws {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

    mutating func encodeIfPresent<T>(_ value: T?, forKey key: KeyType) throws where T : Encodable {
        if let val = value {
            try encode(val, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }

}
