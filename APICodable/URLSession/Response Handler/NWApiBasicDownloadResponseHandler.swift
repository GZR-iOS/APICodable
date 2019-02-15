//
//  NWApiBasicDownloadResponseHandler.swift
//
//  Created by DươngPQ on 30/01/2019.
//

import Foundation

/// Basic response handler to download data to file.
/// Exisiting file will be removed before write new file.
public class NWApiBasicDownloadResponseHandler: NWApiDownloadResponseHandler {

    public let destination: URL
    public var response: HTTPURLResponse?
    public var responseBodyDescription: String? = nil

    public init(_ destUrl: URL) {
        destination = destUrl
    }

    public func processTempFile(_ file: URL) throws {
        responseBodyDescription = nil
        let fileMan = FileManager.default
        if fileMan.fileExists(atPath: destination.path) {
            try fileMan.removeItem(at: destination)
        }
        try fileMan.copyItem(at: file, to: destination)
        responseBodyDescription = destination.path
    }

    public func processResponse(_ header: HTTPURLResponse?) throws {
        response = header
        if let resp = response, resp.statusCode < 200 || resp.statusCode > 299 {
            throw NSError(domain: NWHTTPErrorDomain, code: resp.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: resp.statusCode)])
        }
    }

}
