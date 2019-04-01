//
//  NWExtension.swift
//
//  Created by DươngPQ on 09/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

#if os(OSX)
    import AppKit

    public typealias NWImage = NSImage

    public extension NSImage {

        func pngData() -> Data? {
            var bmp: NSBitmapImageRep? = nil
            if let bitmap = self.representations.first as? NSBitmapImageRep {
                bmp = bitmap
            } else if let imageRep = self.representations.first, let cgImg = imageRep.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                bmp = NSBitmapImageRep(cgImage: cgImg)
            }
            return bmp?.representation(using: .png, properties: [:])
        }

        func jpegData(compressionQuality: CGFloat = 1.0) -> Data? {
            var bmp: NSBitmapImageRep? = nil
            if let bitmap = self.representations.first as? NSBitmapImageRep {
                bmp = bitmap
            } else if let imageRep = self.representations.first, let cgImg = imageRep.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                bmp = NSBitmapImageRep(cgImage: cgImg)
            }
            return bmp?.representation(using: .jpeg, properties: [.compressionFactor: NSNumber(value: Double(compressionQuality))])
        }

    }
#else
    import UIKit

    public typealias NWImage = UIImage

public extension UIImage {
#if swift(>=4.2)
    func jpegData() -> Data? {
        return jpegData(compressionQuality: 1.0)
    }
#else
    public func pngData() -> Data? {
        return UIImagePNGRepresentation(self)
    }

    public func jpegData(compressionQuality: CGFloat = 1.0) -> Data? {
        return UIImageJPEGRepresentation(self, compressionQuality)
    }
#endif
}
#endif

public extension HTTPURLResponse {

    var status: HTTPStatusCode {
        return HTTPStatusCode(self.statusCode)
    }

    func headerValue(_ key: HTTPResponseHeaderField) -> Any? {
        return self.allHeaderFields[key.value]
    }

}

public extension URLRequest {

    mutating func setHttpHeader(key: HTTPRequestHeaderField, value: String?) {
        setValue(value, forHTTPHeaderField: key.value)
    }

    mutating func setMethod(_ method: HTTPMethod) {
        self.httpMethod = method.value
    }

}

public extension String.Encoding {

    init(httpCharset: String) {
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(httpCharset as CFString)
        let result = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
        self.init(rawValue: result)
    }

    var httpContentTypeCharset: String {
        let cfEncoding = CFStringConvertNSStringEncodingToEncoding(self.rawValue)
        return CFStringConvertEncodingToIANACharSetName(cfEncoding) as String
    }

}

public var NWFileExtensionMimeMap: [String: NWContentType] = [
    "txt": NWContentType.applicationOctetStream,
    "csv": (try? NWContentType(type: .text, subType: NWContentType.MainType.TextSubType.csv, parameter: nil))!,
    "html": (try? NWContentType(type: .text, subType: NWContentType.MainType.TextSubType.html, parameter: nil))!,
    "htm": (try? NWContentType(type: .text, subType: NWContentType.MainType.TextSubType.html, parameter: nil))!,
    "jpg": (try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.jpeg, parameter: nil))!,
    "jpeg": (try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.jpeg, parameter: nil))!,
    "png": (try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.png, parameter: nil))!,
    "gif": (try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.gif, parameter: nil))!,
    "mp3": (try? NWContentType(type: .audio, subType: NWContentType.MainType.AudioSubType.mpeg, parameter: nil))!,
    "mp4": (try? NWContentType(type: .video, subType: NWContentType.MainType.VideoSubType.mp4, parameter: nil))!,
    "mpeg": (try? NWContentType(type: .video, subType: NWContentType.MainType.VideoSubType.mpeg, parameter: nil))!,
    "mpg": (try? NWContentType(type: .video, subType: NWContentType.MainType.VideoSubType.mpeg, parameter: nil))!,
    "mov": (try? NWContentType(type: .video, subType: NWContentType.MainType.VideoSubType.quicktime, parameter: nil))!,
    "xml": (try? NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.xml, parameter: nil))!,
    "pdf": (try? NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.pdf, parameter: nil))!,
    "gz": (try? NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.gzip, parameter: nil))!,
    "zip": (try? NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.zip, parameter: nil))!,
    "7z": (try? NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.x7z, parameter: nil))!,
]

extension URL: NWMultipartFormDataSectionData {

    public func convertToMultipartFormDataSection(key: String, encoding: String.Encoding) throws -> NWMultipartFormDataSection {
        if isFileURL {
            let contentType = NWFileExtensionMimeMap[pathExtension.lowercased()] ?? NWContentType.applicationOctetStream
            return try NWMultipartFormDataSection(inputName: key, fromFile: path,
                                                  type: contentType, inputEncoding: encoding)
        }
        return try NWMultipartFormDataSection(inputName: key, value: absoluteString, inputEncoding: encoding)
    }

}

extension NWImage: NWMultipartFormDataSectionData {

    public func convertToMultipartFormDataSection(key: String, encoding: String.Encoding) throws -> NWMultipartFormDataSection {
        return try NWMultipartFormDataSection(inputName: key, jpegImage: self,
                                              fileName: (key as NSString).appendingPathExtension("jpg"),
                                              inputEncoding: encoding)
    }

}

extension Data: NWMultipartFormDataSectionData {

    public func convertToMultipartFormDataSection(key: String, encoding: String.Encoding) throws -> NWMultipartFormDataSection {
        let disposition = try NWContentDisposition(formData: key, fileName: nil, fileNameEncode: encoding)
        return NWMultipartFormDataSection(inputDisposition: disposition, inputType: .applicationOctetStream, data: self, inputEncoding: encoding)
    }

}
