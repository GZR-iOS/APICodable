//
//  NWRfc2183.swift
//
//  Created by DươngPQ on 17/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

// https://tools.ietf.org/html/rfc2183

import Foundation

public class NWContentDisposition: NWABNFHeaderLine {

    public static let paramName = "name"
    public static let paramFileName = "filename"
    public static let paramCreationDate = "creation-date"
    public static let paramModificationDate = "modification-date"
    public static let paramReadDate = "read-date"
    public static let paramSize = "size"

    /// You should validate `filename` yourself (depends filesystem of server)
    public init(type: String, name: String?, fileName: String?, creationDate: Date?, modificationDate: Date?,
                readDate: Date?, size: UInt?, fileNameEncode: String.Encoding = .utf8) throws {
        var cmt = ""
        if let nme = name, nme.count > 0 {
            if (try NWHeaderLine.shouldQuoted(nme)) {
                cmt += NWContentDisposition.paramName + "=\"\(nme)\"; "
            } else {
                cmt += NWContentDisposition.paramName + "=" + nme + "; "
            }
        }
        if var fName = fileName, fName.count > 0 {
            var shouldQuoted = false
            do {
                shouldQuoted = try NWHeaderLine.shouldQuoted(fName)
            } catch {
                shouldQuoted = true
                fName = try NWUrlEncode(raw: fName, reservedChars: nil, unreservedChars: NWURIUnreservedCharacters,
                                        spacePlus: false, hexaLowerCase: false, encoding: fileNameEncode)
            }
            if shouldQuoted {
                cmt += NWContentDisposition.paramFileName + "=\"\(fName)\"; "
            } else {
                cmt += NWContentDisposition.paramFileName + "=" + fName + "; "
            }
        }
        if let date = creationDate {
            cmt += NWContentDisposition.paramCreationDate + "=\"\(HTTPDateTimeFormat.rfc1123.format(date: date))\"; "
        }
        if let date = modificationDate {
            cmt += NWContentDisposition.paramModificationDate + "=\"\(HTTPDateTimeFormat.rfc1123.format(date: date))\"; "
        }
        if let date = readDate {
            cmt += NWContentDisposition.paramReadDate + "=\"\(HTTPDateTimeFormat.rfc1123.format(date: date))\"; "
        }
        if let sze = size {
            cmt += NWContentDisposition.paramSize + "=\(sze); "
        }
        var cmt1: String? = nil
        if cmt.count > 0 {
            cmt1 = String(cmt[..<cmt.index(cmt.endIndex, offsetBy: -2)])
        }
        super.init(key: HTTPRequestHeaderField.contentDisposition.value, value: type, comment: cmt1)
    }

    /// You should validate `filename` yourself (depends filesystem of server)
    public convenience init(formData name: String, fileName: String?, fileNameEncode: String.Encoding = .utf8) throws {
        try self.init(type: NWContentType.MainType.MultipartSubType.formData, name: name, fileName: fileName, creationDate: nil,
                      modificationDate: nil, readDate: nil, size: nil, fileNameEncode: fileNameEncode)
    }

}
