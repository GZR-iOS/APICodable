//
//  NWApiBasicResponseHandler.swift
//
//  Created by DươngPQ on 28/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public let NWHTTPErrorDomain = "HTTPErrorDomain"

/// Very basic response handler, which check response status code & store response data as binary.
open class NWApiBasicResponseHandler: NWApiDataResponseHandler {

    public private(set) var body: Data?
    public private(set) var response: HTTPURLResponse?

    public var responseBodyDescription: String? = nil

    public init() {

    }

    open func processResponse(data: Data?, header: HTTPURLResponse?) throws {
        body = data
        response = header
        if let resp = response {
            if resp.statusCode < 200 || resp.statusCode > 299 {
                throw NSError(domain: NWHTTPErrorDomain, code: resp.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: resp.statusCode)])
            }
        }
    }

}
