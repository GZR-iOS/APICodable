//
//  NWUrlQueryBuilder.swift
//
//  Created by DươngPQ on 11/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

// Reference http://tools.ietf.org/html/rfc3986

/// Class helps to make URL query (URL encoded parameters)
public class NWUrlQueryBuilder {

    public struct QueryParameter {
        public var keyPath: NWKeyPath
        public var value: String
    }

    /// Encode space as `%20` or `+` (if `escapedCharacters` contains space, this option has no effect).
    public var spacePlus = false
    /// Hexa code in lowercase or uppercase
    public var hexaLowerCase = false
    /// **ASCII** characters to escaped from query. Default is list of characters defined in `http://tools.ietf.org/html/rfc3986` (`NWURIUnreservedCharacters`).
    public var unescapingCharacters = NWURIQueryCharacters.subtracting(CharacterSet(charactersIn: "?/&="))
    /// String Encoding for URL encode
    public var encoding = String.Encoding.utf8
    /// Encode array index as key (ex: `&key1[]=item0&key1[]=item1&...` vs `&key1[0]=item0&key1[1]=item1&...`).
    public var arrayIndexAsKey = false

    private var parameters = [QueryParameter]()

    public func addParamater(_ param: QueryParameter) {
        parameters.append(param)
    }

    public func getValue(_ keyPath: NWKeyPath) -> QueryParameter? {
        for item in parameters where NWKeyPathEqual(left: item.keyPath, right: keyPath) {
            return item
        }
        return nil
    }

    public func removeParameter(_ keyPath: NWKeyPath) -> QueryParameter? {
        for (index, item) in parameters.enumerated() where NWKeyPathEqual(left: item.keyPath, right: keyPath) {
            return parameters.remove(at: index)
        }
        return nil
    }

    public func removeAll() {
        parameters.removeAll()
    }

    /// Apply only for direct key (use `addParameter(_:)` to add parameter with key for array/dictionary).
    public subscript(_ key: String) -> String? {
        get {
            return getValue([NWKeyPathType.key(key)])?.value
        }
        set {
            let targetKeyPath = [NWKeyPathType.key(key)]
            if let val = newValue {
                var target: Int? = nil
                for (index, item) in parameters.enumerated() where NWKeyPathEqual(left: item.keyPath, right: targetKeyPath) {
                    target = index
                    break
                }
                if let index = target {
                    var param = parameters[index]
                    param.value = val
                    parameters[index] = param
                } else {
                    let param = QueryParameter(keyPath: targetKeyPath, value: val)
                    parameters.append(param)
                }
            } else {
                _ = removeParameter(targetKeyPath)
            }
        }
    }

    public func addParameters(from query: String) -> Int {
        let components = query.components(separatedBy: "&")
        var arrayCounts = [String: UInt]()
        var result = [QueryParameter]()
        if components.count > 0 {
            for item in components {
                let keyValue = item.components(separatedBy: "=")
                if keyValue.count == 2, let key = NWUrlDecode(input: keyValue[0]), let value = NWUrlDecode(input: keyValue[1]) {
                    if key.contains("[") {
                        var keyPath = NWKeyPath()
                        let keyComp = key.components(separatedBy: "[")
                        var mainKey = ""
                        for (index, keyItem) in keyComp.enumerated() {
                            if keyItem.count == 0 {
                                return 0
                            }
                            if index == 0 {
                                keyPath.append(NWKeyPathType.key(keyItem))
                                mainKey = keyItem
                            } else if let range = keyItem.range(of: "]"), range.upperBound == keyItem.endIndex {
                                let keyItemKey = String(keyItem[..<range.lowerBound])
                                if keyItemKey.count > 0 {
                                    keyPath.append(NWKeyPathType.key(keyItemKey))
                                } else {
                                    let currentIndex = arrayCounts[mainKey] ?? 0
                                    keyPath.append(NWKeyPathType.unkey(currentIndex))
                                    arrayCounts[mainKey] = currentIndex + 1
                                }
                            } else {
                                return 0
                            }
                        }
                        let param = QueryParameter(keyPath: keyPath, value: value)
                        result.append(param)
                    } else {
                        let param = QueryParameter(keyPath: [.key(key)], value: value)
                        result.append(param)
                    }
                } else {
                    return 0
                }
            }
        }
        parameters.append(contentsOf: result)
        return result.count
    }

    private func urlEncode(_ raw: String) throws -> String {
        return try NWUrlEncode(raw: raw, reservedChars: nil, unreservedChars: unescapingCharacters,
                               spacePlus: spacePlus, hexaLowerCase: hexaLowerCase, encoding: encoding)
    }

    public func generate() throws -> String {
        var result = ""
        for item in parameters {
            var key = ""
            for (index, path) in item.keyPath.enumerated() {
                switch path {
                case .key(let pathKey):
                    if index == 0 {
                        key += try urlEncode(pathKey)
                    } else {
                        key += try urlEncode("[" + pathKey + "]")
                    }
                case .unkey(let index):
                    if arrayIndexAsKey {
                        key += try urlEncode("[\(index)]")
                    } else {
                        key += try urlEncode("[]")
                    }
                }
            }
            if key.count > 0 {
                result += key + "=" + (try urlEncode(item.value)) + "&"
            }
        }
        if result.count > 0 {
            return String(result[..<result.index(before: result.endIndex)])
        }
        return result
    }

}
