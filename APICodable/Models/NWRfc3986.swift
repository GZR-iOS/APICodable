//
//  NWRfc3986.swift
//
//  Created by DươngPQ on 15/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Unreversed characters from https://tools.ietf.org/html/rfc1808 (obsoleted)
public let NWURLUnreservedSafeExtraCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~$-_.+!*'(),")
/// Reversed characters from https://tools.ietf.org/html/rfc1808 (obsoleted)
public let NWURLReservedCharacters = CharacterSet(charactersIn: ";/?:@&=")

public let NWURIAlphaHightCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
public let NWURIAlphaLowCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
public let NWURIDigitCharacters = CharacterSet(charactersIn: "0123456789")
public let NWURIAlphaNumericCharacters = NWURIAlphaHightCharacters.union(NWURIAlphaLowCharacters).union(NWURIDigitCharacters)
/// Unreversed characters from https://tools.ietf.org/html/rfc3986
public let NWURIUnreservedCharacters = CharacterSet(charactersIn: "-._~").union(NWURIAlphaNumericCharacters)
public let NWURIGenDelimsCharacters = CharacterSet(charactersIn: ":/?#[]@")
public let NWURISubDelimsCharacters = CharacterSet(charactersIn: "!$&'()*+;=")
/// Reversed characters from https://tools.ietf.org/html/rfc3986
public let NWURIReservedCharacters = NWURIGenDelimsCharacters.union(NWURISubDelimsCharacters)
/// Valid characters for URI scheme from https://tools.ietf.org/html/rfc3986, not allow other characters
public let NWURISchemeCharacters = CharacterSet(charactersIn: "+-.").union(NWURIAlphaNumericCharacters)
/// Non-required escaping characters for URI UserInfo from https://tools.ietf.org/html/rfc3986.
/// Password is not allowed in URI (but I still use `NWURIUnreservedCharacters` to URL encode password because NSURL still supports).
public let NWURIUserInfoCharacters = NWURIUnreservedCharacters.union(NWURISubDelimsCharacters).union(CharacterSet(charactersIn: ":"))
/// Non-required escaping characters for URI Host Domain Name from https://tools.ietf.org/html/rfc3986.
public let NWURIDomainNamCharacters = NWURIUnreservedCharacters.union(NWURISubDelimsCharacters)
/// Only digits (~ UInt)
public let NWURIPortCharacters = NWURIDigitCharacters
/// Non-required escaping characters for URI Path from https://tools.ietf.org/html/rfc3986.
public let NWURIPathComponentCharacters = NWURIUnreservedCharacters.union(NWURISubDelimsCharacters).union(CharacterSet(charactersIn: "@:"))
/// Non-required escaping characters for URI Query from https://tools.ietf.org/html/rfc3986.
public let NWURIQueryCharacters = NWURIPathComponentCharacters.union(CharacterSet(charactersIn: "/?"))
/// Non-required escaping characters for URI Fragment from https://tools.ietf.org/html/rfc3986.
public let NWURIFragmentCharacters = NWURIQueryCharacters

public let NWHexaCharacterss = CharacterSet(charactersIn: "ABCDEFabcdef").union(NWURIDigitCharacters)

/// Check that the given `raw` string contains only ASCII characters in `charSet`.
public func NWValidateString(raw: String, charSet: CharacterSet) -> Bool {
    for char in raw {
        if char.unicodeScalars.count == 1, let charU = char.unicodeScalars.first, charU.isASCII {
            if !charSet.contains(charU) {
                return false
            }
        } else {
            return false
        }
    }
    return true
}

/* Encode raw string into percent-encoded string

 - Parameters:
   - raw: Input string
   - reservedChars: List of ASCII reserved charaters. Reserved characters will be transformed into `%hexhex`.
   - unreservedChars: List of ASCII Unreserved characters. Unreserved characters remains as original (except `reservedChars` containing it already).
   - spacePlus: Force transform ` ` (space SP) into `+` instead of `%hexhex`.
   - hexaLowCase: if true, use lower case hexa characters for `%hexhex`.
   - encoding: String encoding used to transform characters into `%hexhex`.
 - Returns: Encoded string
 - Throws: Error if failed to transform character into `%hexhex` using given string encoding.
 */
public func NWUrlEncode(raw: String, reservedChars: CharacterSet?, unreservedChars: CharacterSet?,
                        spacePlus: Bool = false, hexaLowerCase: Bool = false, encoding: String.Encoding = .utf8) throws -> String {
    var result = ""
    for char in raw {
        if let data = String(char).data(using: encoding) {
            var shouldEscape = true
            if data.count == 1, let byte = data.first {
                let charU = Unicode.Scalar(byte)
                if charU.isASCII {
                    if let reserved = reservedChars, reserved.contains(charU) {
                        shouldEscape = true
                    } else if let unreserved = unreservedChars, unreserved.contains(charU) {
                        shouldEscape = false
                    }
                }
            }
            if shouldEscape {
                if spacePlus, char == " " {
                    result.append("+")
                } else {
                    for byte in data {
                        result.append(String(format: hexaLowerCase ? "%%%02x" : "%%%02X", byte))
                    }
                }
            } else {
                result.append(char)
            }
        } else {
            throw NWError.encoding
        }
    }
    return result
}

/* Decode a Percent-Encoded string

 - Parameters:
   - input: Percent-Encoded string
   - spacePlus: `input` use `+` for space or not
   - encoding: String encoding. Default UTF8.
 - Returns: nil if failed.
 */
public func NWUrlDecode(input: String, spacePlus: Bool = false, encoding: String.Encoding = .utf8) -> String? {
    guard input.count > 0 else { return input }
    var hex = "" // max length 2
    var decodingValues = [UInt8]()
    var result = ""
    var isEncoding = false

    let finishDecoding: () -> Bool = {
        let data = Data(bytes: decodingValues)
        if let str = String(data: data, encoding: encoding) {
            result += str
        } else {
            return false
        }
        decodingValues.removeAll()
        return true
    }

    for char in input {
        if char.unicodeScalars.count == 1, let charU = char.unicodeScalars.first, charU.isASCII {
            if isEncoding {
                if !NWHexaCharacterss.contains(charU) {
                    var tmp: String? = nil
                    if hex.count < 2 {
                        return nil
                    }
                    if hex.count > 2 {
                        tmp = String(hex[hex.index(hex.startIndex, offsetBy: 2)...])
                        hex = String(hex[..<hex.index(hex.startIndex, offsetBy: 2)])
                    }
                    if let val = UInt8(hex, radix: 16) {
                        decodingValues.append(val)
                        hex = ""
                    } else {
                        return nil
                    }
                    if char == "%" {
                        if let str = tmp {
                            if !finishDecoding() {
                                return nil
                            }
                            result.append(str)
                        }
                        continue
                    }
                    if !finishDecoding() {
                        return nil
                    }
                    if let str = tmp {
                        result.append(str)
                    }
                    isEncoding = false
                    if char == "+", spacePlus {
                        result.append(" ")
                    } else {
                        result.append(char)
                    }
                } else {
                    hex.append(char)
                }
            } else if char == "%" {
                isEncoding = true
            } else {
                if char == "+", spacePlus {
                    result.append(" ")
                } else {
                    result.append(char)
                }
            }
        } else {
            return nil
        }
    }
    if isEncoding {
        var tmp: String? = nil
        if hex.count < 2 {
            return nil
        }
        if hex.count > 2 {
            tmp = String(hex[hex.index(hex.startIndex, offsetBy: 2)...])
            hex = String(hex[..<hex.index(hex.startIndex, offsetBy: 2)])
        }
        if let val = UInt8(hex, radix: 16) {
            decodingValues.append(val)
        } else {
            return nil
        }
        if !finishDecoding() {
            return nil
        }
        if let str = tmp {
            result.append(str)
        }
    }
    return result
}
