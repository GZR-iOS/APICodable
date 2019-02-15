//
//  NWApiMultipartFormDataRequestMaker.swift
//  APICodable
//
//  Created by DươngPQ on 31/01/2019.
//

import Foundation

/// Create an empty file in Temporary folder & open it for writting
public func NWMakeTempFile() -> (FileHandle, String)? {
    let fileMan = FileManager.default
    let name = ProcessInfo.processInfo.globallyUniqueString
    let tempDir: String
    if #available(iOS 10.0, *) {
        tempDir = fileMan.temporaryDirectory.path
    } else {
        tempDir = NSTemporaryDirectory()
    }
    var index = 0
    var lastName = name
    var path = (tempDir as NSString).appendingPathComponent(lastName)
    while fileMan.fileExists(atPath: path) {
        lastName = name + "\(index)"
        path = (tempDir as NSString).appendingPathComponent(lastName)
        index += 1
    }
    fileMan.createFile(atPath: path, contents: nil, attributes: nil)
    if let handler = FileHandle(forWritingAtPath: path) {
        return (handler, path)
    }
    return nil
}

/// Make URLRequest with POST method & body data in Multipart/Form-Data format (using URLSessionDataTask).
/// Require NWApiRequest parameter be Encodable instance.
public class NWApiMultipartFormDataRequestMaker: NWApiRequestDataMaker {

    public var encoding = String.Encoding.utf8

    public init() {}

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestDataMakerReturnType {
        var result = URLRequest(url: sender.url)
        var desc: String?
        if let pparam = parameter {
            if let param = pparam as? Encodable {
                let encoder = NWMultipartFormDataEncoder()
                encoder.encoding = encoding
                let (data, debugDesc) = try encoder.encode(param)
                result.httpBody = data
                desc = debugDesc
                let contentType = encoder.builder.contentTypeBoundary
                result.setValue(contentType.body, forHTTPHeaderField: contentType.name)
                result.setHttpHeader(key: .contentLength, value: "\(data.count)")
            } else {
                throw NWError.parameterNotEncodable
            }
        }
        result.setMethod(.post)
        return NWApiRequestDataMakerReturnType(request: result, debugDescription: desc)
    }

}

/// Make URLRequest with POST method & body data in Multipart/Form-Data format (using URLSessionUploadTask).
/// Require NWApiRequest parameter be Encodable instance.
public class NWApiMultipartFormDataUploadRequestMaker: NWApiRequestUploadMaker {

    public enum MultipartFormDataUploadRequestMakerError: NWErrorType {
        case failToCreateTempFile
    }

    /// Save formatted data into temp file & upload it
    public var useTempFile = true
    public var encoding = String.Encoding.utf8

    public init() {}

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestUploadMakerReturnType {
        var result = URLRequest(url: sender.url)
        var desc: String?
        var tempFile: String?
        var uplData: Data?

        if useTempFile {
            if let pparam = parameter {
                if let param = pparam as? Encodable {
                    let encoder = NWMultipartFormDataEncoder()
                    encoder.encoding = encoding
                    if let (writter, tempPath) = NWMakeTempFile() {
                        desc = (try encoder.write(value: param, handler: writter)) + "\nTEMP FILE: " + tempPath
                        writter.closeFile()
                        tempFile = tempPath
                        let contentType = encoder.builder.contentTypeBoundary
                        result.setValue(contentType.body, forHTTPHeaderField: contentType.name)
                        if let attr = try? FileManager.default.attributesOfItem(atPath: tempPath) as NSDictionary {
                            result.setHttpHeader(key: .contentLength, value: "\(attr.fileSize())")
                        }
                    } else {
                        throw MultipartFormDataUploadRequestMakerError.failToCreateTempFile
                    }
                } else {
                    throw NWError.parameterNotEncodable
                }
            }
        } else {
            if let pparam = parameter {
                if let param = pparam as? Encodable {
                    let encoder = NWMultipartFormDataEncoder()
                    encoder.encoding = encoding
                    let (data, debugDesc) = try encoder.encode(param)
                    uplData = data
                    desc = debugDesc
                    let contentType = encoder.builder.contentTypeBoundary
                    result.setValue(contentType.body, forHTTPHeaderField: contentType.name)
                    result.setHttpHeader(key: .contentLength, value: "\(data.count)")
                } else {
                    throw NWError.parameterNotEncodable
                }
            }
        }
        result.setMethod(.post)
        return NWApiRequestUploadMakerReturnType(request: result, file: tempFile, isTemp: true, data: uplData, debugDescription: desc)
    }

}
