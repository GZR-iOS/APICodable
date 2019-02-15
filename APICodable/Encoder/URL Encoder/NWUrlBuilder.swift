//
//  NWUrlBuilder.swift
//
//  Created by DươngPQ on 15/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Reference: http://tools.ietf.org/html/rfc3986

public typealias NWIPv4 = (UInt8, UInt8, UInt8, UInt8)
public typealias NWIPv6Normal = (UInt16?, UInt16?, UInt16?, UInt16?, UInt16?, UInt16?, UInt16?, UInt16?)
public typealias NWIPv6Dual = (UInt16?, UInt16?, UInt16?, UInt16?, UInt16?, UInt16?, UInt8, UInt8, UInt8, UInt8)

/// Generate URL from parts
public class NWUrlBuilder {

    public enum UrlBuilderError: NWErrorType {
        /// Scheme contains invalid character
        case invalidScheme
    }

    public enum HostType {
        case domainName(String)
        case ipv4(NWIPv4)
        case ipv6Normal(NWIPv6Normal)
        case ipv6Dual(NWIPv6Dual)
    }

    public var schemeValidCharacters = NWURISchemeCharacters
    public var userUnescapingCharacters = NWURIUserInfoCharacters
    public var passwordUnescapingCharacters = NWURIUnreservedCharacters
    public var domainNameUnescapingCharacters = NWURIDomainNamCharacters
    public var pathUnescapingCharacters = NWURIPathComponentCharacters
    public var fragmentUnescapingCharacters = NWURIFragmentCharacters

    public var scheme: URIScheme?
    public var user: String?
    public var password: String?
    public var host: HostType?
    public var port: UInt?
    public var pathComponents = [String]()
    public var query: NWUrlQueryBuilder?
    public var fragment: String?

    public var encoding = String.Encoding.utf8

    public init(url: URL, spacePlus: Bool = false, stringEncoding: String.Encoding = .utf8) {
        encoding = stringEncoding
        if let urlScheme = url.scheme {
            scheme = URIScheme(urlScheme)
        }
        for item in url.pathComponents where item != "/" {
            pathComponents.append(item)
        }
        user = url.user
        password = url.password
        if let urlHost = url.host {
            if urlHost.contains("%"), let decoded = NWUrlDecode(input: urlHost, spacePlus: spacePlus, encoding: encoding) {
                host = HostType.domainName(decoded)
            } else if urlHost.contains(":") && urlHost.contains(".") {
                let components = urlHost.components(separatedBy: ":")
                var ipv6 = [UInt16?]()
                var ipv4 = [UInt8]()
                if components.count == 7 {
                    for (index, item) in components.enumerated() {
                        if index == 6 {
                            let components4 = item.components(separatedBy: ".")
                            if components4.count == 4 {
                                for item4 in components4 {
                                    if item4.count > 0, item4.count <= 3, let value = UInt8(item4) {
                                        ipv4.append(value)
                                    } else {
                                        break
                                    }
                                }
                            } else {
                                break
                            }
                        } else {
                            if item.count == 0 {
                                ipv6.append(nil)
                            } else if item.count > 0, item.count <= 4, let value = UInt16(item, radix: 16) {
                                ipv6.append(value)
                            } else {
                                break
                            }
                        }
                    }
                }
                if ipv4.count == 4 && ipv6.count == 6 {
                    host = HostType.ipv6Dual((ipv6[0], ipv6[1], ipv6[2], ipv6[3], ipv6[4], ipv6[5], ipv4[0], ipv4[1], ipv4[2], ipv4[3]))
                }
            } else if urlHost.contains(".") {
                var ipv4 = [UInt8]()
                let components4 = urlHost.components(separatedBy: ".")
                if components4.count == 4 {
                    for item4 in components4 {
                        if item4.count > 0, item4.count <= 3, let value = UInt8(item4) {
                            ipv4.append(value)
                        } else {
                            break
                        }
                    }
                    if ipv4.count == components4.count {
                        host = HostType.ipv4((ipv4[0], ipv4[1], ipv4[2], ipv4[3]))
                    }
                }
            } else if urlHost.contains(":") {
                var ipv6 = [UInt16?]()
                let components = urlHost.components(separatedBy: ":")
                if components.count == 8 {
                    for item in components {
                        if item.count == 0 {
                            ipv6.append(nil)
                        } else if item.count > 0, item.count <= 4, let value = UInt16(item, radix: 16) {
                            ipv6.append(value)
                        } else {
                            break
                        }
                    }
                    if ipv6.count == components.count {
                        host = HostType.ipv6Normal((ipv6[0], ipv6[1], ipv6[2], ipv6[3], ipv6[4], ipv6[5], ipv6[6], ipv6[7]))
                    }
                }
            }
            if host == nil {
                host = HostType.domainName(urlHost)
            }
        }
        if let prt = url.port {
            port = UInt(prt)
        }
        if let queryStr = url.query {
            let queryBuilder = NWUrlQueryBuilder()
            queryBuilder.spacePlus = spacePlus
            queryBuilder.encoding = encoding
            if queryBuilder.addParameters(from: queryStr) > 0 {
                query = queryBuilder
            }
        }
        if let urlFragment = url.fragment {
            fragment = NWUrlDecode(input: urlFragment, spacePlus: false, encoding: encoding)
        }
    }

    public init() {

    }

    public func setPath(_ path: String) {
        pathComponents.removeAll()
        let components = path.components(separatedBy: "/")
        for item in components where item.count > 0 {
            pathComponents.append(item)
        }
    }

    public func generateAbsoluteString(hexaLowerCase: Bool = false) throws -> String {
        var result = ""
        if let sch = scheme {
            if !NWValidateString(raw: sch.value, charSet: schemeValidCharacters) {
                throw UrlBuilderError.invalidScheme
            }
            result = sch.value + ":"
        }
        var authority = ""
        if let usr = user {
            authority += try NWUrlEncode(raw: usr, reservedChars: nil, unreservedChars: userUnescapingCharacters,
                                     spacePlus: false, hexaLowerCase: hexaLowerCase, encoding: encoding)

        }
        if let pass = password {
            authority += ":" + (try NWUrlEncode(raw: pass, reservedChars: nil, unreservedChars: passwordUnescapingCharacters,
                                                spacePlus: false, hexaLowerCase: hexaLowerCase, encoding: encoding))
        }
        if authority.count > 0 {
            authority += "@"
        }
        if let hst = host {
            switch hst {
            case .ipv4(let ips):
                authority += "\(ips.0).\(ips.1).\(ips.2).\(ips.3)"
            case .ipv6Normal(let ips):
                authority += "["
                if let val = ips.0 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.1 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.2 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.3 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.4 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.5 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.6 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.7 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += "]"
            case .ipv6Dual(let ips):
                authority += "["
                if let val = ips.0 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.1 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.2 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.3 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.4 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":"
                if let val = ips.5 {
                    authority += String(format: hexaLowerCase ? "%4x" : "%4X", val)
                }
                authority += ":\(ips.6).\(ips.7).\(ips.8).\(ips.9)"
                authority += "]"
            case .domainName(let name):
                authority += try NWUrlEncode(raw: name, reservedChars: nil, unreservedChars: domainNameUnescapingCharacters,
                                             spacePlus: false, hexaLowerCase: hexaLowerCase, encoding: encoding)
            }
        }
        if let prt = port {
            authority += ":\(prt)"
        }
        if authority.count > 0 {
            result += "//" + authority
        }
        var tail = ""
        if pathComponents.count > 0 {
            for path in pathComponents {
                tail += (try NWUrlEncode(raw: path, reservedChars: nil, unreservedChars: pathUnescapingCharacters,
                                         spacePlus: false, hexaLowerCase: hexaLowerCase, encoding: encoding)) + "/"
            }
            tail = String(tail[..<tail.index(before: tail.endIndex)])
        }
        if let queryBuilder = query {
            queryBuilder.hexaLowerCase = hexaLowerCase
            queryBuilder.encoding = encoding
            let queryStr = try queryBuilder.generate()
            if queryStr.count > 0 {
                tail += "?" + queryStr
            }
        }
        if let frag = fragment {
            tail += "#" + (try NWUrlEncode(raw: frag, reservedChars: nil, unreservedChars: fragmentUnescapingCharacters,
                                           spacePlus: false, hexaLowerCase: hexaLowerCase, encoding: encoding))
        }
        if tail.count > 0 {
            result += "/" + tail
        }
        return result
    }

    public func generate() throws -> URL? {
        return URL(string: try generateAbsoluteString())
    }

}
