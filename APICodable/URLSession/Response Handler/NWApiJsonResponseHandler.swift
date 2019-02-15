//
//  NWApiJsonResponseHandler.swift
//  APICodable
//
//  Created by DươngPQ on 01/02/2019.
//

import Foundation

open class NWApiJsonResponseHandler<ResponseType>: NWApiDataResponseHandler where ResponseType: Decodable {

    public private(set) var response: HTTPURLResponse?
    public var responseBodyDescription: String? = nil
    public var decoder = JSONDecoder()
    public private(set) var responseObject: ResponseType?

    public init() {}

    open func processResponse(data: Data?, header: HTTPURLResponse?) throws {
        if let resp = response {
            if resp.statusCode < 200 || resp.statusCode > 299 {
                throw NSError(domain: NWHTTPErrorDomain, code: resp.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: resp.statusCode)])
            }
        }
        if let jsonData = data {
            let decoder = JSONDecoder()
            responseObject = try decoder.decode(ResponseType.self, from: jsonData)
            if let obj = responseObject {
                responseBodyDescription = "\(obj)"
            }
        }
    }

}
