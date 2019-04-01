//
//  NWApiRequestExtension.swift
//
//  Created by DươngPQ on 29/01/2019.
//

import Foundation

public extension NWApiRequest {

    private convenience init<ResponseType: Decodable>(type: NWApiFormUrlEncodedRequestMaker.RequestType,
                                                      url: URL, parameter: Encodable?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type) {
        let maker = NWApiFormUrlEncodedRequestMaker(type)
        let handler = NWApiJsonResponseHandler<ResponseType>()
        var args = NWApiRequest.DataRequestArgument(request: maker, response: handler)
        args.parameter = parameter
        args.successAction = onSuccess
        args.failureAction = onFailure
        self.init(link: url, rqType: .data(args))
    }

    /// Create new request for GET request (parameter in form-data/url-encoded as URL query) and JSON response
    convenience init<ResponseType: Decodable>(get url: URL, parameter: Encodable?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type) {
        self.init(type: .urlQuery, url: url, parameter: parameter, onSuccess: onSuccess,
                  onFailure: onFailure, jsonResponseModel: jsonResponseModel)
    }

    /// Create new request for POST request (parameter in form-data/url-encoded as request body) and JSON response
    convenience init<ResponseType: Decodable>(post url: URL, parameter: Encodable?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type) {
        self.init(type: .requestBody, url: url, parameter: parameter, onSuccess: onSuccess,
                  onFailure: onFailure, jsonResponseModel: jsonResponseModel)
    }

    /// Create new request for POST request (parameter in application/json as request body) and JSON response
    convenience init<ResponseType: Decodable>(json url: URL, parameter: Encodable?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type) {
        let maker = NWApiJsonRequestMaker()
        let handler = NWApiJsonResponseHandler<ResponseType>()
        var args = NWApiRequest.DataRequestArgument(request: maker, response: handler)
        args.parameter = parameter
        args.successAction = onSuccess
        args.failureAction = onFailure
        self.init(link: url, rqType: .data(args))
    }

    /// Create new request for POST request (parameter in multipart/form-data as request body) and JSON response
    convenience init<ResponseType: Decodable>(multipart url: URL, parameter: Encodable?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type) {
        let maker = NWApiMultipartFormDataRequestMaker()
        let handler = NWApiJsonResponseHandler<ResponseType>()
        var args = NWApiRequest.DataRequestArgument(request: maker, response: handler)
        args.parameter = parameter
        args.successAction = onSuccess
        args.failureAction = onFailure
        self.init(link: url, rqType: .data(args))
    }

    /// Create new request for POST request (parameter should be 1 of <String, Data, UIImage> only) as request body;
    /// if *useUploadTask == true*, parameter can be `URL` to file to upload) and JSON response
    convenience init<ResponseType: Decodable>(raw url: URL, parameter: Any?, onSuccess: DataSuccessAction?,
                                                     onFailure: DataFailureAction?, jsonResponseModel: ResponseType.Type,
                                                     useUploadTask: Bool = false) {
        if useUploadTask {
            let maker = NWApiBasicUploadRequestMaker()
            let handler = NWApiJsonResponseHandler<ResponseType>()
            var args = NWApiRequest.UploadRequestArgument(request: maker, response: handler)
            args.parameter = parameter
            args.successAction = onSuccess
            args.failureAction = onFailure
            self.init(link: url, rqType: .upload(args))
        } else {
            let maker = NWApiBasicBodyRequestMaker()
            let handler = NWApiJsonResponseHandler<ResponseType>()
            var args = NWApiRequest.DataRequestArgument(request: maker, response: handler)
            args.parameter = parameter
            args.successAction = onSuccess
            args.failureAction = onFailure
            self.init(link: url, rqType: .data(args))
        }
    }

    private convenience init(type: NWApiFormUrlEncodedRequestMaker.RequestType, url: URL,
                             parameter: Encodable?, onSuccess: DownloadSuccessAction?,
                             onFailure: DownloadFailureAction?, destination: URL) {
        let maker = NWApiFormUrlEncodedRequestMaker(type)
        let handler = NWApiBasicDownloadResponseHandler(destination)
        var args = NWApiRequest.DownloadRequestArgument(request: maker, response: handler)
        args.parameter = parameter
        args.successAction = onSuccess
        args.failureAction = onFailure
        self.init(link: url, rqType: .download(args))
    }

    /// Create new request for GET request (parameter in form-data/url-encoded as URL query), download response to *destination* file path.
    convenience init(downloadGet url: URL, parameter: Encodable?, onSuccess: DownloadSuccessAction?,
                             onFailure: DownloadFailureAction?, destination: URL) {
        self.init(type: .urlQuery, url: url, parameter: parameter, onSuccess: onSuccess, onFailure: onFailure, destination: destination)
    }

    /// Create new request for POST request (parameter in form-data/url-encoded as request body), download response to *destination* file path.
    convenience init(downloadPost url: URL, parameter: Encodable?, onSuccess: DownloadSuccessAction?,
                            onFailure: DownloadFailureAction?, destination: URL) {
        self.init(type: .urlQuery, url: url, parameter: parameter, onSuccess: onSuccess, onFailure: onFailure, destination: destination)
    }

}
