//
//  NWApiBasicBodyRequestMaker.swift
//
//  Created by DươngPQ on 30/01/2019.
//

import Foundation

public enum NWBasicRequestMakerError: NWErrorType {
    case notSupportedParameter
}

fileprivate func NWProcessParameter(parameter: Any?, defaultContentType: NWContentType?) throws -> (Data?, NWContentType?, String?)? {
    if let param = parameter {
        var body: Data? = nil
        var ctType: NWContentType? = nil
        var desc: String? = nil
        if let image = param as? NWImage {
            if let type = defaultContentType {
                let typeVal = type.getValueAndParameters().0.lowercased()
                if typeVal == (NWContentType.MainType.image.value + "/" + NWContentType.MainType.ImageSubType.png) {
                    body = image.pngData()
                    ctType = type
                    desc = "PNG Image \(image.size.width)x\(image.size.height)"
                }
            }
            if body == nil {
                body = image.jpegData()
                desc = "JPEG Image \(image.size.width)x\(image.size.height) Compress 1 (best quality)"
                ctType = try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.jpeg, parameter: nil)
            }
        } else if let data = param as? Data {
            body = data
            ctType = defaultContentType ?? NWContentType.applicationOctetStream
        } else if let str = param as? String {
            var encoding = String.Encoding.utf8
            if let type = defaultContentType, let parameters = type.getValueAndParameters().1,
                let charset = parameters[NWContentType.MainType.TextSubType.paramCharset] {
                encoding = String.Encoding(httpCharset: charset)
                ctType = type
            } else {
                ctType = NWContentType.textPlainUtf8
            }
            body = str.data(using: encoding)
        } else {
            throw NWBasicRequestMakerError.notSupportedParameter
        }
        return (body, ctType, desc)
    }
    return nil
}

/**
 Make request using given parameter as body.
 - *Parameter* should be: UIImage, NSData, String.
 - UIImage *parameter* without contenType will be convert to JPEG data (compress level 1) by default.
 - This set request header *Content-Type* & *Content-Length*.
 */
public class NWApiBasicBodyRequestMaker: NWApiRequestDataMaker {

    public var contentType: NWContentType?

    public init() {}

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestDataMakerReturnType {
        var request = URLRequest(url: sender.url)
        var desc: String? = nil
        if let (body, ctType, desc1) = try NWProcessParameter(parameter: parameter, defaultContentType: contentType) {
            request.httpBody = body
            if let type = ctType {
                request.setHttpHeader(key: .contentType, value: type.body)
            }
            if let data = body {
                request.setHttpHeader(key: .contentLength, value: "\(data.count)")
            }
            desc = desc1
        }
        request.setMethod(.post)
        return NWApiRequestDataMakerReturnType(request: request, debugDescription: desc)
    }

}

/**
 Make upload request using given parameter as body.
 - *Parameter* should be: UIImage, NSData, String, file URL.
 - UIImage *parameter* without contenType will be convert to JPEG data (compress level 1) by default.
 - This set request header *Content-Type* & *Content-Length*.
 */
public class NWApiBasicUploadRequestMaker: NWApiRequestUploadMaker {

    public var contentType: NWContentType?

    public init() {}

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestUploadMakerReturnType {
        var request = URLRequest(url: sender.url)
        var desc: String? = nil
        var data: Data? = nil
        var path: String? = nil
        do {
            if let (body, ctType, desc1) = try NWProcessParameter(parameter: parameter, defaultContentType: contentType) {
                data = body
                desc = desc1
                if let type = ctType {
                    request.setHttpHeader(key: .contentType, value: type.body)
                }
            }
        } catch (let err) {
            if let url = parameter as? URL, url.isFileURL {
                path = url.path
                desc = "Upload from file \"\(url.path)\""
                if let type = contentType {
                    request.setHttpHeader(key: .contentType, value: type.body)
                }
            } else {
                throw err
            }
        }
        request.setMethod(.post)
        return NWApiRequestUploadMakerReturnType(request: request, file: path, isTemp: false, data: data, debugDescription: desc)
    }

}

