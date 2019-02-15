//
//  NWKeyPathEncoderDelegate.swift
//
//  Created by DươngPQ on 15/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public enum NWKeyPathType {
    case key(String)
    case unkey(UInt)
}

public typealias NWKeyPath = [NWKeyPathType]

public func NWKeyPathEqual(left: NWKeyPath, right: NWKeyPath) -> Bool {
    if left.count == right.count {
        for itemL in left {
            for itemR in right {
                switch itemL {
                case .key(let keyL):
                    switch itemR {
                    case .key(let keyR):
                        if keyL != keyR {
                            return false
                        }
                    default:
                        return false
                    }
                case .unkey(let indexL):
                    switch itemR {
                    case .unkey(let indexR):
                        if indexL != indexR {
                            return false
                        }
                    default:
                        return false
                    }
                }
            }
        }
        return true
    }
    return false
}

public func NWKeyPathFromString(_ input: String) -> NWKeyPath {
    // TODO:
    return [NWKeyPathType.key(input)]
}

public protocol NWKeyPathEncoderDelegate: class {

    /// Required
    func encode(value: String, keyPath: NWKeyPath) throws
    /// Required
    func encode(value: Bool, keyPath: NWKeyPath) throws
    /// Required
    func encode(value: Double, keyPath: NWKeyPath) throws
    /// Required
    func encode(value: Int, keyPath: NWKeyPath) throws
    /// Required
    func encode(value: UInt, keyPath: NWKeyPath) throws

    /// Return `false` if delegate processes the value itself. Return `true` to continue encoding with key-path.
    /// Default returned value is `true`.
    func encode<Type>(value: Type, keyPath: NWKeyPath) throws -> Bool where Type : Encodable

    /// Optional. Return `true` to increase count number of unkeyed container. Default do nothing and return `true`.
    func encodeNil(keyPath: NWKeyPath) throws -> Bool
    /// Optional. Default convert value & encode to `Int`.
    func encode(value: Int8, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `Int`.
    func encode(value: Int16, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `Int`.
    func encode(value: Int32, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `Int`.
    func encode(value: Int64, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `UInt`.
    func encode(value: UInt8, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `UInt`.
    func encode(value: UInt16, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `UInt`.
    func encode(value: UInt32, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `UInt`.
    func encode(value: UInt64, keyPath: NWKeyPath) throws
    /// Optional. Default convert value & encode to `Double`.
    func encode(value: Float, keyPath: NWKeyPath) throws

}

public extension NWKeyPathEncoderDelegate {

    func encodeNil(keyPath: NWKeyPath) throws -> Bool {
        return true
    }

    func encode(value: Int8, keyPath: NWKeyPath) throws {
        try encode(value: Int(value), keyPath: keyPath)
    }

    func encode(value: Int16, keyPath: NWKeyPath) throws {
        try encode(value: Int(value), keyPath: keyPath)
    }

    func encode(value: Int32, keyPath: NWKeyPath) throws {
        try encode(value: Int(value), keyPath: keyPath)
    }

    func encode(value: Int64, keyPath: NWKeyPath) throws {
        try encode(value: Int(value), keyPath: keyPath)
    }

    func encode(value: UInt8, keyPath: NWKeyPath) throws {
        try encode(value: UInt(value), keyPath: keyPath)
    }

    func encode(value: UInt16, keyPath: NWKeyPath) throws {
        try encode(value: UInt(value), keyPath: keyPath)
    }

    func encode(value: UInt32, keyPath: NWKeyPath) throws {
        try encode(value: UInt(value), keyPath: keyPath)
    }

    func encode(value: UInt64, keyPath: NWKeyPath) throws {
        try encode(value: UInt(value), keyPath: keyPath)
    }

    func encode(value: Float, keyPath: NWKeyPath) throws {
        try encode(value: Double(value), keyPath: keyPath)
    }

    func encode<Type>(value: Type, keyPath: NWKeyPath) throws -> Bool where Type : Encodable {
        return true
    }
    
}
