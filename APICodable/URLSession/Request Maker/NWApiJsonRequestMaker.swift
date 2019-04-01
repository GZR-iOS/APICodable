//
//  NWApiJsonRequestMaker.swift
//
//  Created by DươngPQ on 25/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public extension Encodable {

    func toJsonData(_ encoder: JSONEncoder) throws -> Data {
        return try encoder.encode(self)
    }

}

/// Generate POST request with JSON body data.
/// - Require *parameter* be *Encodable* model.
/// - This set request header *Content-Type* & *Content-Length*.
public class NWApiJsonRequestMaker: NWApiRequestDataMaker {

    public var jsonEncoder = JSONEncoder()

    public init() {}

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestDataMakerReturnType {
        var result = URLRequest(url: sender.url)
        if let pparam = parameter {
            if let param = pparam as? Encodable {
                let query = try param.toJsonData(jsonEncoder)
                result.httpBody = query
                result.setHttpHeader(key: .contentLength, value: "\(query.count)")
                let contentType = try NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.json,
                                                    parameter: (NWContentType.MainType.TextSubType.paramCharset, String.Encoding.utf8.httpContentTypeCharset))
                result.setValue(contentType.body, forHTTPHeaderField: contentType.name)
            } else {
                throw NWError.parameterNotEncodable
            }
        }
        result.setMethod(.post)
        return NWApiRequestDataMakerReturnType(request: result, debugDescription: nil)
    }

}

