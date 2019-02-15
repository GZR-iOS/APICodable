//
//  NWMultipartFormDataBuilder.swift
//
//  Created by DươngPQ on 11/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// https://tools.ietf.org/html/rfc7578
public class NWMultipartFormDataBuilder {

    public let boundary: String
    public let contentTypeBoundary: NWContentType
    public var parts = [NWMultipartFormDataSection]()

    /// `separator` is multipart boundary. It should be printable US-ASCII characters and not contained in parts.
    public init(_ separator: String) throws {
        boundary = separator
        contentTypeBoundary = try NWContentType(multipart: NWContentType.MainType.MultipartSubType.formData, boundary: separator)
    }

    public convenience init() {
        let sep = "xxx" + HTTPDateTimeFormat("yyyyMMddHHmmss").format(date: Date()) + "xxx"
        try! self.init(sep)
    }

    public func generate(_ encoding: String.Encoding = .utf8) throws -> (Data, String) {
        guard let crlfData = NWCRLF.data(using: encoding), let boundaryData = ("--" + boundary).data(using: encoding) else {
            throw NWError.encoding
        }
        var log = ""
        var result = Data()
        for part in parts {
            result.append(boundaryData)
            result.append(crlfData)
            log += "--" + boundary + "\n"
            let (partData, partLog) = try part.generateFormattedData()
            result.append(partData)
            result.append(crlfData)
            log += partLog + "\n"
        }
        result.append(boundaryData)
        if let endData = "--".data(using: encoding) {
            result.append(endData)
        } else {
            throw NWError.encoding
        }
        log += "--\(boundary)--"
        return (result, log)
    }

    public func write(_ handler: FileHandle, encoding: String.Encoding = .utf8) throws -> String {
        guard let crlfData = NWCRLF.data(using: encoding), let boundaryData = ("--" + boundary).data(using: encoding) else {
            throw NWError.encoding
        }
        var log = ""
        for part in parts {
            handler.write(boundaryData)
            handler.write(crlfData)
            log += "--" + boundary + "\n"
            let partLog = try part.writeToFile(handler)
            handler.write(crlfData)
            log += partLog + "\n"
        }
        handler.write(boundaryData)
        if let endData = "--".data(using: encoding) {
            handler.write(endData)
        } else {
            throw NWError.encoding
        }
        log += "--\(boundary)--"
        return log
    }

}
