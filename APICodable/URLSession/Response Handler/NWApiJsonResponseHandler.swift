//
//  NWApiJsonResponseHandler.swift
//  APICodable
//
//  Created by DươngPQ on 01/02/2019.
//

import Foundation
import CommonLog

open class NWApiJsonResponseHandler<ResponseType>: NWApiDataResponseHandler where ResponseType: Decodable {

    public private(set) var rawData: Data?
    public private(set) var header: HTTPURLResponse?
    public var responseBodyDescription: String? = nil
    public var decoder = JSONDecoder()
    public private(set) var responseObject: ResponseType?

    public init() {}

    open func processResponse(data: Data?, response: HTTPURLResponse?) throws {
        if let resp = header {
            if resp.statusCode < 200 || resp.statusCode > 299 {
                throw NSError(domain: NWHTTPErrorDomain, code: resp.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: resp.statusCode)])
            }
        }
        rawData = data
        header = response
        if let jsonData = rawData {
            let decoder = JSONDecoder()
            CMLog(jsonData.base64EncodedString(), try? JSONSerialization.jsonObject(with: jsonData, options: .init(rawValue: 0)))
            responseObject = try decoder.decode(ResponseType.self, from: jsonData)
            if let obj = responseObject {
                responseBodyDescription = "\(obj)"
            }
        }
    }

}
