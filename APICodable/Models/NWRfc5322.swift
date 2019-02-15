//
//  NWRfc5322.swift
//
//  Created by DươngPQ on 17/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

// https://tools.ietf.org/html/rfc5322

import Foundation

public let NWMaxHeaderLineLength = 998
public let NWRecommendHeaderLineLength = 78

/// Header line. Not support Folding.
open class NWHeaderLine {

    public enum HeaderLineError: NWErrorType {
        case nameContainsInvalidCharacter
        case bodyContainsInvalidCharacter
        case nameLength
        case bodyLength
    }

    public let name: String
    public let body: String

    public init(key: String, value: String) {
        name = key
        body = value
    }

    /// Header name must be printable ASCII characters excluding space & colon.
    open func validateName() -> Bool {
        if let data = name.data(using: .ascii) {
            for byte in data where byte < 33 || byte > 126 || byte == 58 {
                return false
            }
        } else {
            return false
        }
        return true
    }

    /// Header value (Unstructured) must be printable ASCII including space, HTab
    open func validateBody() -> Bool {
        if let data = body.data(using: .ascii) {
            for byte in data where (byte < 32 || byte > 126) && byte != 9 {
                return false
            }
        } else {
            return false
        }
        return true
    }

    open func generateLine() throws -> String {
        if name.count == 0 {
            throw HeaderLineError.nameLength
        }
        if !validateName() {
            throw HeaderLineError.nameContainsInvalidCharacter
        }
        if body.count > NWMaxHeaderLineLength {
            throw HeaderLineError.bodyLength
        }
        if !validateBody() {
            throw HeaderLineError.bodyContainsInvalidCharacter
        }
        return name + ": " + body
    }

    static public func shouldQuoted(_ input: String) throws -> Bool {
        var shouldQuote = false
        if let valData = input.data(using: .ascii) {
            for byte in valData {
                if NWMimeEspecialsCharacters.contains(Unicode.Scalar(byte)) || byte == 0x20 {
                    shouldQuote = true
                } else if byte < 33 || byte > 126 {
                    throw HeaderLineError.bodyContainsInvalidCharacter
                }
            }
        } else {
            throw HeaderLineError.bodyContainsInvalidCharacter
        }
        return shouldQuote
    }

}
