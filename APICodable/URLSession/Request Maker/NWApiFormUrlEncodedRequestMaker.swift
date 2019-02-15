//
//  NWApiGetRequestMaker.swift
//
//  Created by DươngPQ on 21/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Generate request with form-data url-encoded format (in URL query (GET) or in request body (POST)).
/// - Require *parameter* be *Encodable* model.
/// - In case of POST request, this will set request header *Content-Type* & *Content-Length*.
public class NWApiFormUrlEncodedRequestMaker: NWApiRequestDataMaker {

    /// Type of request
    public enum RequestType {
        /// Put parameters in URL query
        case urlQuery
        /// Put parameters in request body
        case requestBody
    }

    public enum GetRequestMakerError: NWErrorType {
        case failCreateUrl
    }

    public let type: RequestType
    /// Configure query builder (see **NWUrlQueryBuilder** description).
    public var queryConfiguration: ((NWUrlQueryBuilder) -> Void)?

    public init(_ requestType: RequestType) {
        type = requestType
    }

    public func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestDataMakerReturnType {
        switch type {
        case .urlQuery:
            return NWApiRequestDataMakerReturnType(request: (try generateUrlRequest(sender: sender, parameter: parameter)), debugDescription: nil)
        case .requestBody:
            return NWApiRequestDataMakerReturnType(request: (try generateBodyRequest(sender: sender, parameter: parameter)), debugDescription: nil)
        }
    }
    
    private func generateUrlRequest(sender: NWApiRequest, parameter: Any?) throws -> URLRequest {
        let urlMaker = NWUrlBuilder(url: sender.url)
        let queryBuilder = urlMaker.query ?? NWUrlQueryBuilder()
        if let config = queryConfiguration {
            config(queryBuilder)
        }
        if let pparam = parameter {
            if let param = pparam as? Encodable {
                let encoder = NWUrlEncoder(queryBuilder)
                _ = try encoder.encode(param)
            } else {
                throw NWError.parameterNotEncodable
            }
        }
        urlMaker.query = queryBuilder
        if let url = try urlMaker.generate() {
            var result = URLRequest(url: url)
            result.setMethod(.get)
            return result
        } else {
            throw GetRequestMakerError.failCreateUrl
        }
    }

    private func generateBodyRequest(sender: NWApiRequest, parameter: Any?) throws -> URLRequest {
        var result = URLRequest(url: sender.url)
        if let pparam = parameter {
            if let param = pparam as? Encodable {
                let encoder = NWUrlEncoder()
                if let config = queryConfiguration {
                    config(encoder.builder)
                }
                let query = try encoder.encode(param)
                if let data = query.data(using: .ascii) {
                    result.httpBody = data
                    result.setHttpHeader(key: .contentLength, value: "\(data.count)")
                    let contentType = try NWContentType(type: .application, subType: NWContentType.MainType.ApplicationSubType.xWwwForm,
                                                        parameter: (NWContentType.MainType.TextSubType.paramCharset, encoder.builder.encoding.httpContentTypeCharset))
                    result.setValue(contentType.body, forHTTPHeaderField: contentType.name)
                }
            } else {
                throw NWError.parameterNotEncodable
            }
        }
        result.setMethod(.post)
        return result
    }

}
