//
//  NWMultipartFormDataEncoder.swift
//
//  Created by DươngPQ on 11/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public class NWMultipartFormDataEncoder: NWKeyPathEncoderDelegate {

    public enum MultipartFormDataError: NWErrorType {
        case failToWriteFile
    }

    public let builder: NWMultipartFormDataBuilder
    private let encoder = NWKeyPathEncoder()
    public var encoding = String.Encoding.utf8

    public init() {
        builder = NWMultipartFormDataBuilder()
        encoder.delegate = self
    }

    public init(boundary: String) throws {
        builder = try NWMultipartFormDataBuilder(boundary)
        encoder.delegate = self
    }

    public func encode(_ value: Encodable) throws -> (Data, String) {
        builder.parts.removeAll()
        try value.encode(to: encoder)
        let result = try builder.generate()
        return result
    }

    public func write(value: Encodable, handler: FileHandle) throws -> String {
        builder.parts.removeAll()
        try value.encode(to: encoder)
        let result = try builder.write(handler, encoding: encoding)
        return result
    }

    public func write(value: Encodable, writeTo file: String) throws -> String {
        let fileMan = FileManager.default
        if fileMan.fileExists(atPath: file) {
            try fileMan.removeItem(atPath: file)
        }
        try Data().write(to: URL(fileURLWithPath: file))
        if let handler = FileHandle(forWritingAtPath: file) {
            return try write(value: value, handler: handler)
        } else {
            throw MultipartFormDataError.failToWriteFile
        }
    }

    private func makeKey(keyPath: NWKeyPath) -> String {
        var result = ""
        for (index, item) in keyPath.enumerated() {
            switch item {
            case .key(let key):
                if index == 0 {
                    result += key
                } else {
                    result += "[\(key)]"
                }
            case .unkey(_):
                result += "[]"
            }
        }
        return result
    }

    /// MARK: - Key-Path encoder delegate

    public func encode(value: String, keyPath: NWKeyPath) throws {
        let part = try NWMultipartFormDataSection(inputName: makeKey(keyPath: keyPath), value: value, inputEncoding: encoding)
        builder.parts.append(part)
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

    public func encode<Type>(value: Type, keyPath: NWKeyPath) throws -> Bool where Type : Encodable {
        if let sectionValue = value as? NWMultipartFormDataSectionData {
            builder.parts.append(try sectionValue.convertToMultipartFormDataSection(key: makeKey(keyPath: keyPath), encoding: encoding))
            return false
        }
        return true
    }

}
