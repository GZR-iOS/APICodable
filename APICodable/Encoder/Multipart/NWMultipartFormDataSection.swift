//
//  NWMultipartFormDataSection.swift
//
//  Created by DươngPQ on 11/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public protocol NWMultipartFormDataSectionData: Encodable {

    func convertToMultipartFormDataSection(key: String, encoding: String.Encoding) throws -> NWMultipartFormDataSection

}

public extension NWMultipartFormDataSectionData {

    func encode(to encoder: Encoder) throws {
        if !(encoder is NWMultipartFormDataEncoder) {
            throw NWError.notSupport
        }
    }

}

public struct NWMultipartFormDataSection: NWMultipartFormDataSectionData {

    /// Not log content if data is bigger
    static var maxLogDataSize = 1024

    public let encoding: String.Encoding
    public let contentDisposition: NWContentDisposition
    public let contentType: NWContentType
    public let rawData: Data

    public init(inputDisposition: NWContentDisposition, inputType: NWContentType, data: Data,
                inputEncoding: String.Encoding = .utf8) {
        contentDisposition = inputDisposition
        contentType = inputType
        rawData = data
        encoding = inputEncoding
    }

    public init(inputName: String, fromFile: String, type: NWContentType = .applicationOctetStream,
                inputEncoding: String.Encoding = .utf8) throws {
        contentDisposition = try NWContentDisposition(formData: inputName, fileName: (fromFile as NSString).lastPathComponent,
                                                      fileNameEncode: inputEncoding)
        encoding = inputEncoding
        contentType = type
        let url = URL(fileURLWithPath: fromFile)
        rawData = try Data(contentsOf: url, options: .mappedIfSafe)
    }

    private func getAllAttributes() -> [NWHeaderLine] {
        return [contentDisposition, contentType]
    }

    private func getRawDataDesc() -> String {
        if rawData.count <= NWMultipartFormDataSection.maxLogDataSize,
            let desc = String(data: rawData, encoding: encoding) {
            return desc
        }
        return "BINARY: \(rawData.count)"
    }

    func generateFormattedData() throws -> (Data, String) {
        guard let newLineData = NWCRLF.data(using: encoding) else {
            throw NWError.encoding
        }
        var resultData = Data()
        var resultLog = ""
        let allAttributes = getAllAttributes()

        for attr in allAttributes {
            let attrStr = try attr.generateLine()
            if let attrData = attrStr.data(using: encoding) {
                resultData.append(attrData)
                resultData.append(newLineData)
                resultLog += attrStr + "\n"
            }
        }
        resultData.append(newLineData)
        resultLog += "\n"
        resultData.append(rawData)
        resultLog += getRawDataDesc()
        return (resultData, resultLog)
    }

    func writeToFile(_ handler: FileHandle) throws -> String {
        var resultLog = ""
        let newLineData = NWCRLF.data(using: encoding) ?? Data()
        let allAttributes = getAllAttributes()
        for attr in allAttributes {
            let attrStr = try attr.generateLine()
            if let attrData = attrStr.data(using: encoding) {
                handler.write(attrData)
                handler.write(newLineData)
                resultLog += attrStr + "\n"
            }
        }
        handler.write(newLineData)
        resultLog += "\n"
        handler.write(rawData)
        resultLog += getRawDataDesc()
        return resultLog
    }

    public func convertToMultipartFormDataSection(key: String, encoding: String.Encoding) throws -> NWMultipartFormDataSection {
        return self
    }

}

public extension NWMultipartFormDataSection {

    enum MultipartFormDataSectionError: NWErrorType {
        case failToMakePNGData
        case failToMakeJPEGData
    }

    init(inputName: String, value: String, inputEncoding: String.Encoding = .utf8) throws {
        contentDisposition = try NWContentDisposition(formData: inputName, fileName: nil, fileNameEncode: inputEncoding)
        rawData = value.data(using: inputEncoding) ?? Data()
        encoding = inputEncoding
        contentType = try NWContentType(text: NWContentType.MainType.TextSubType.plain, charset: inputEncoding)
    }

    init(inputName: String, pngImage: NWImage, fileName: String? = nil, inputEncoding: String.Encoding = .utf8) throws {
        encoding = inputEncoding
        contentDisposition = try NWContentDisposition(formData: inputName, fileName: fileName)
        contentType = try NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.png, parameter: nil)
        if let data = pngImage.pngData() {
            rawData = data
        } else {
            throw MultipartFormDataSectionError.failToMakePNGData
        }
    }

    init(inputName: String, jpegImage: NWImage, quality: CGFloat = 1.0,
                fileName: String? = nil, inputEncoding: String.Encoding = .utf8) throws {
        encoding = inputEncoding
        contentDisposition = try NWContentDisposition(formData: inputName, fileName: fileName)
        contentType = try NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.jpeg, parameter: nil)
        if let data = jpegImage.jpegData(compressionQuality: quality) {
            rawData = data
        } else {
            throw MultipartFormDataSectionError.failToMakeJPEGData
        }
    }

}
