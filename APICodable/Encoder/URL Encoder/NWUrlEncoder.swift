//
//  NWUrlEncoder.swift
//
//  Created by DươngPQ on 04/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Encode encodable model into query string for URL (`application/x-www-form-urlencoded`)
public class NWUrlEncoder: NWKeyPathEncoderDelegate {

    public let builder: NWUrlQueryBuilder
    /// Encode nil value as empty text (ex: `&key1=&key2=...`)
    public var allowNull = false
    private let encoder = NWKeyPathEncoder()

    public init() {
        builder = NWUrlQueryBuilder()
        encoder.delegate = self
    }

    public init(_ queryBuilder: NWUrlQueryBuilder) {
        builder = queryBuilder
        encoder.delegate = self
    }

    public func encode(_ value: Encodable) throws -> String {
        if value is [Any] {
            throw NWError.notSupport
        }
        builder.removeAll()
        try value.encode(to: encoder)
        let result = try builder.generate()
        return result
    }

    /// MARK: - Key-Path encoder delegate

    public func encode(value: String, keyPath: NWKeyPath) throws {
        let param = NWUrlQueryBuilder.QueryParameter(keyPath: keyPath, value: value)
        builder.addParamater(param)
    }

    public func encode(value: Bool, keyPath: NWKeyPath) throws {
        try encode(value: value ? "1": "0", keyPath: keyPath)
    }

    public func encode(value: Int, keyPath: NWKeyPath) throws {
        try encode(value: "\(value)", keyPath: keyPath)
    }

    public func encode(value: UInt, keyPath: NWKeyPath) throws {
        try encode(value: "\(value)", keyPath: keyPath)
    }

    public func encode(value: Double, keyPath: NWKeyPath) throws {
        try encode(value: "\(value)", keyPath: keyPath)
    }

    public func encodeNil(keyPath: NWKeyPath) throws -> Bool {
        if allowNull {
            try encode(value: "", keyPath: keyPath)
            return true
        }
        return false
    }

}
