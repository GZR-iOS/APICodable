//
//  NWApiRequest.swift
//
//  Created by DươngPQ on 21/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import CommonLog

public struct NWApiRequestDataMakerReturnType {
    let request: URLRequest
    let debugDescription: String?
}

/// Protocol for request maker to use NSUrlSessionDataTask
public protocol NWApiRequestDataMaker {
    /** Return:
     - Request
     - Request body description (optional)
     */
    func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestDataMakerReturnType
}

public struct NWApiRequestUploadMakerReturnType {
    let request: URLRequest
    let file: String?
    let isTemp: Bool
    let data: Data?
    let debugDescription: String?
}

/// Protocol for request maker which makes request data from file & use NSURLSessionUploadTask
public protocol NWApiRequestUploadMaker {
    /** Return:
     - Request
     - File to upload. True if this is temp file (remove it when request finish).
     - Data to upload (ignored if file != nil). Error if file & data are both nil.
     - Request body description (optional)
     */
    func generateRequest(sender: NWApiRequest, parameter: Any?) throws -> NWApiRequestUploadMakerReturnType
}

/// Protocol for data response handler
public protocol NWApiDataResponseHandler {

    var rawData: Data? { get }
    var header: HTTPURLResponse?  { get }

    var responseBodyDescription: String? { get }
    func processResponse(data: Data?, response: HTTPURLResponse?) throws
}

/// Protocol for download response handler
public protocol NWApiDownloadResponseHandler {
    var responseBodyDescription: String? { get }
    /// Note: this function run in NWApiManager operation queue (not in NWApiRequest queue) like other function (to copy file).
    func processTempFile(_ file: URL) throws
    func processResponse(_ header: HTTPURLResponse?) throws
}

/**
 Class to request data using URLSession tasks.

 - Main init method: init(link:, rqType:).
 - Pre-require when create a request:
   - Url of request.
   - Which type of URLSession task will be used: data, upload, download.
   - Which type of URLRequest, which HTTP method => use equivalent Request Maker => use valid parameter
   - Which type of response data => choose Response Handler: almost JSON

 We can use directly *NWApiRequest* to request data.

 But I recommend subclass for each project:
 - Init: configure the pre-requirement request for project.
 - Subclass can override func *configureRequest(_:)* to add common header rather than add for each request if we use dirently *NWApiRequest*.
 - Subclass can override func *requestDidFinish(_:) -> Bool* to process common error.
 */
open class NWApiRequest {

    public enum ApiRequestError: NWErrorType {
        /// No session with given configuration name
        case sessionNotFound
        /// Current request instance started & not finish yet
        case alreadyLoading
        /// Uploading request maker returns wrong result (*parameter* must satisfy uploade maker requirement).
        case invalidUploadMaker
    }

    public enum State {
        /// Request just is made
        case made
        /// Request starts making URLRequest
        case start
        /// Request started URLSessionTask & sendind data
        case sending
        /// Request received header from server
        case connected
        /// Request is receiving response data
        case receiving
        /// Request did finish
        case finished
        /// Request did cancel
        case cancelled
    }

    public typealias TransferDelegateAction = (_ bytesProcessed: Int64, _ totalBytesProcessed: Int64,
        _ totalBytesExpected: Int64, _ instanceSpeed: Double, _ averageSpeed: Double) -> Void

    public typealias DataSuccessAction = (_ sender: NWApiRequest, _ response: NWApiDataResponseHandler) -> Void
    public typealias DataFailureAction = (_ sender: NWApiRequest, _ response: NWApiDataResponseHandler, _ error: Error) -> Void
    public struct DataRequestArgument {
        /// Object to generate URLRequest
        public let requestMaker: NWApiRequestDataMaker
        /// Parameter data to pass to *requestMaker`. Depend of *requestMaker* requirement, *parameter* should be right type.
        public var parameter: Any?
        /// Object to parse & store response data.
        public let responseHandler: NWApiDataResponseHandler
        /// Action when request (including making URLRequest, get data via URLSession, parse response data) is success.
        public var successAction: DataSuccessAction?
        /// Action when request fails.
        public var failureAction: DataFailureAction?

        public init(request: NWApiRequestDataMaker, response: NWApiDataResponseHandler) {
            requestMaker = request
            responseHandler = response
        }
    }
    public typealias DownloadSuccessAction = (_ sender: NWApiRequest, _ response: NWApiDownloadResponseHandler) -> Void
    public typealias DownloadFailureAction = (_ sender: NWApiRequest, _ response: NWApiDownloadResponseHandler, _ error: Error) -> Void
    public typealias DownloadCancelAction = (Data) -> Void
    public struct DownloadRequestArgument {
        /// Object to generate URLRequest
        public let requestMaker: NWApiRequestDataMaker
        /// Parameter data to pass to *requestMaker`. Depend of *requestMaker* requirement, *parameter* should be right type.
        public var parameter: Any?
        /// Object to parse & store response data.
        public let responseHandler: NWApiDownloadResponseHandler
        /// Action when request (including making URLRequest, get data via URLSession, parse response data) is success.
        public var successAction: DownloadSuccessAction?
        /// Action when request fails.
        public var failureAction: DownloadFailureAction?
        /// Action to process resumable data when cancel request
        public var cancelAction: DownloadCancelAction?

        public init(request: NWApiRequestDataMaker, response: NWApiDownloadResponseHandler) {
            requestMaker = request
            responseHandler = response
        }
    }

    public struct UploadRequestArgument {
        /// Object to generate URLRequest
        public let requestMaker: NWApiRequestUploadMaker
        /// Parameter data to pass to *requestMaker`. Depend of *requestMaker* requirement, *parameter* should be right type.
        public var parameter: Any?
        /// Object to parse & store response data.
        public let responseHandler: NWApiDataResponseHandler
        /// Action when request (including making URLRequest, get data via URLSession, parse response data) is success.
        public var successAction: DataSuccessAction?
        /// Action when request fails.
        public var failureAction: DataFailureAction?

        public init(request: NWApiRequestUploadMaker, response: NWApiDataResponseHandler) {
            requestMaker = request
            responseHandler = response
        }
    }
    public struct ResumeRequestArgument {
        /// Resumable data (returned when cancel downloading request)
        public let resumeData: Data
        /// Object to parse & store response data.
        public let responseHandler: NWApiDownloadResponseHandler
        /// Action when request is success.
        public var successAction: DownloadSuccessAction?
        /// Action when request fails.
        public var failureAction: DownloadFailureAction?
        /// Action to process resumable data when cancel request
        public var cancelAction: DownloadCancelAction?

        public init (data: Data, response: NWApiDownloadResponseHandler) {
            resumeData = data
            responseHandler = response
        }
    }

    public enum RequestType {
        case data(DataRequestArgument)
        case download(DownloadRequestArgument)
        case upload(UploadRequestArgument)
        case resume(ResumeRequestArgument)
    }

    public let taskType: RequestType
    public private(set) var state: State = .made
    public internal(set) var isAuthenticationFailed = false
    public let url: URL
    public var requestConfigurationAction: ((inout URLRequest) -> Void)?
    /// Sending progress action: (bytes send, total bytes send, total bytes to send, instance speed, average speed)
    public var sendingProgressAction: TransferDelegateAction?
    public var downloadProgressAction: TransferDelegateAction?

    var task: URLSessionTask?
    private var uploadFile: String?
    private var buffer: Data?
    private var startingDate: Date?
    private var lastDate: Date?
    private var totalBytes: Int64 = 0
    private let queue = OperationQueue()
    private var dlError: Error? = nil

    public var isLoading: Bool {
        return task != nil
    }

    deinit {
        CMLog("NWApiRequest<\(Unmanaged.passUnretained(self).toOpaque())> dies!", category: CMLogger.LogCategory.info, group: NWLogGroup)
    }

    public init(link: URL, rqType: RequestType) {
        url = link
        taskType = rqType
        queue.maxConcurrentOperationCount = 1
    }

    public convenience init(resume: ResumeRequestArgument) {
        self.init(link: Bundle.main.bundleURL, rqType: RequestType.resume(resume))
    }

    private func startTask(_ tsk: URLSessionTask, session: String, bodyDesc: String?) {
        NWApiManager.shared.registRequest(request: self, session: session)
        task = tsk
        tsk.resume()
        state = .sending
        buffer = nil
        startingDate = Date()
        lastDate = startingDate
        if let request = tsk.currentRequest {
            CMLog(block: { () -> String in
                return NWGetRequestDescription(request: request, bodyDesc: bodyDesc)
            }, category: .info, group: NWLogGroup)
        }
    }

    private func makeDataRequest(session: URLSession, sessionName: String, maker: NWApiRequestDataMaker, parameter: Any?) {
        do {
            let result = try maker.generateRequest(sender: self, parameter: parameter)
            var req = result.request
            configureRequest(&req)
            startTask(session.dataTask(with: req), session: sessionName, bodyDesc: result.debugDescription)
        } catch (let err) {
            finishRequest(with: err)
        }
    }

    private func makeUploadRequest(session: URLSession, sessionName: String, maker: NWApiRequestUploadMaker, parameter: Any?) {
        do {
            let result = try maker.generateRequest(sender: self, parameter: parameter)
            var req = result.request
            configureRequest(&req)
            if let file = result.file {
                if result.isTemp {
                    uploadFile = file
                }
                let tsk = session.uploadTask(with: req, fromFile: URL(fileURLWithPath: file))
                startTask(tsk, session: sessionName, bodyDesc: result.debugDescription)
            } else if let dat = result.data {
                let tsk = session.uploadTask(with: req, from: dat)
                startTask(tsk, session: sessionName, bodyDesc: result.debugDescription)
            } else {
                finishRequest(with: ApiRequestError.invalidUploadMaker)
            }
        } catch (let err) {
            finishRequest(with: err)
        }
    }

    private func makeDownloadRequest(session: URLSession, sessionName: String, maker: NWApiRequestDataMaker, parameter: Any?) {
        do {
            let result = try maker.generateRequest(sender: self, parameter: parameter)
            var req = result.request
            configureRequest(&req)
            startTask(session.downloadTask(with: req), session: sessionName, bodyDesc: result.debugDescription)
        } catch (let err) {
            finishRequest(with: err)
        }
    }

    private func makeResumeRequest(session: URLSession, sessionName: String, data: Data) {
        startTask(session.downloadTask(withResumeData: data), session: sessionName, bodyDesc: nil)
    }

    /// Start request using session with given configuration key
    open func start(_ configName: String = NWApiManager.kDefaultSessionName) throws {
        if isLoading {
            throw ApiRequestError.alreadyLoading
        }
        dlError = nil
        isAuthenticationFailed = false
        if let session = NWApiManager.shared.getSession(configName) {
            let mSelf = self
            queue.addOperation {
                mSelf.state = .start
                switch mSelf.taskType {
                case .data(let args):
                    mSelf.makeDataRequest(session: session, sessionName: configName, maker: args.requestMaker, parameter: args.parameter)
                case .upload(let args):
                    mSelf.makeUploadRequest(session: session, sessionName: configName, maker: args.requestMaker, parameter: args.parameter)
                case .download(let args):
                    mSelf.makeDownloadRequest(session: session, sessionName: configName, maker: args.requestMaker, parameter: args.parameter)
                case .resume(let args):
                    mSelf.makeResumeRequest(session: session, sessionName: configName, data: args.resumeData)
                }
            }
        } else {
            CMLog("Session '\(configName)' not found!", category: CMLogger.LogCategory.critical, group: NWLogGroup)
            throw ApiRequestError.sessionNotFound
        }
    }

    open func cancel() {
        let mSelf = self
        queue.addOperation {
            guard let task = mSelf.task else { return }
            NWApiManager.shared.cancelRequest(request: mSelf, task: task, completion: { data in
                mSelf.state = .cancelled
                switch mSelf.taskType {
                case .download(let args):
                    if let dat = data, let action = args.cancelAction {
                        DispatchQueue.main.async {
                            action(dat)
                        }
                    }
                case .resume(let args):
                    if let dat = data, let action = args.cancelAction {
                        DispatchQueue.main.async {
                            action(dat)
                        }
                    }
                case .upload(_):
                    if let file = mSelf.uploadFile {
                        try? FileManager.default.removeItem(atPath: file)
                    }
                default:
                    break
                }
            })
        }
    }

    open func configureRequest(_ request: inout URLRequest) {
        if let action = requestConfigurationAction {
            action(&request)
        }
    }

    /// Subclass can use this function to process actions before return result to receiver.
    /// In case *error* available, return *true* to igonore failure action set in RequestType (ex. subclass process some common error).
    open func requestDidFinish(_ error: Error?) -> Bool {
        // Subclass
        return false
    }

    // MARK: - Session

    private func logResponse(_ additionalJob: (() -> String)?, category: CMLogger.LogCategory, logTask: URLSessionTask?,
                             functionName: String = #function, fileName: String = #file, lineNum: Int = #line) {
        let data = buffer
        CMLog(block: { () -> String in
            var result = NWGetResponseDescription(task: logTask, data: data)
            if let action = additionalJob {
                result += "\n" + action()
            }
            return result
        }, category: category, group: NWLogGroup, functionName: functionName, fileName: fileName, lineNum: lineNum)
    }

    private func logRequestFinish(error: Error, category: CMLogger.LogCategory, logTask: URLSessionTask?,
                                  functionName: String = #function, fileName: String = #file, lineNum: Int = #line) {
        CMLog(error, category: category, group: NWLogGroup, functionName: functionName, fileName: fileName, lineNum: lineNum)
    }

    private func finishRequest(with error: Error, logCategory: CMLogger.LogCategory = .critical, task: URLSessionTask? = nil) {
        logRequestFinish(error: error, category: logCategory, logTask: task)
        state = .finished
        let mSelf = self
        switch taskType {
        case .data(let args):
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(error), let action = args.failureAction {
                    action(mSelf, args.responseHandler, error)
                }
            }
        case .download(let args):
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(error), let action = args.failureAction {
                    action(mSelf, args.responseHandler, error)
                }
            }
        case .resume(let args):
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(error), let action = args.failureAction {
                    action(mSelf, args.responseHandler, error)
                }
            }
        case .upload(let args):
            if let file = uploadFile {
                try? FileManager.default.removeItem(atPath: file)
            }
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(error), let action = args.failureAction {
                    action(mSelf, args.responseHandler, error)
                }
            }
        }
    }

    func didReceive(response: URLResponse, completion: @escaping (URLSession.ResponseDisposition) -> Void) {
        let mSelf = self
        queue.addOperation {
            mSelf.state = .connected
            if let httpResponse = response as? HTTPURLResponse, let contentLength = httpResponse.headerValue(HTTPResponseHeaderField.contentLength) as? String,
                let value = Int64(contentLength) {
                mSelf.totalBytes = value
            }
            completion(.allow)
        }
    }

    func didReceive(_ data: Data) {
        let mSelf = self
        queue.addOperation {
            mSelf.state = .receiving
            var dat = mSelf.buffer ?? Data()
            dat.append(data)
            mSelf.buffer = dat
            guard let action = mSelf.downloadProgressAction else { return }
            let bytes = Int64(data.count)
            let total = Int64(dat.count)
            var instSpeed = 0.0
            var avgSpeed = 0.0
            let now = Date()
            if let last = mSelf.lastDate {
                instSpeed = Double(bytes) / now.timeIntervalSince(last)
            }
            mSelf.lastDate = now
            if let start = mSelf.startingDate {
                avgSpeed = Double(total) / now.timeIntervalSince(start)
            }
            DispatchQueue.main.async {
                action(bytes, total, mSelf.totalBytes, instSpeed, avgSpeed)
            }
        }
    }

    private func dataOrUploadDidComplete(handler: NWApiDataResponseHandler, successAction: DataSuccessAction?,
                                         failureAction: DataFailureAction?, task: URLSessionTask?) {
        let mSelf = self
        do {
            try handler.processResponse(data: buffer, response: task?.response as? HTTPURLResponse)
            if let desc = handler.responseBodyDescription {
                logResponse({ () -> String in
                    return "DEVELOPMENT INFO:\n" + desc
                }, category: .info, logTask: task)
            } else {
                logResponse(nil, category: .info, logTask: task)
            }
            DispatchQueue.main.async {
                _ = mSelf.requestDidFinish(nil)
            }
            if let action = successAction {
                DispatchQueue.main.async {
                    action(mSelf, handler)
                }
            }
        } catch (let error) {
            logRequestFinish(error: error, category: .warning, logTask: task)
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(error), let action = failureAction {
                    action(mSelf, handler, error)
                }
            }
        }
    }

    private func dataDidComplete(args: DataRequestArgument, task: URLSessionTask?) {
        dataOrUploadDidComplete(handler: args.responseHandler, successAction: args.successAction,
                                failureAction: args.failureAction, task: task)
    }

    private func uploadDidComplete(args: UploadRequestArgument, task: URLSessionTask?) {
        dataOrUploadDidComplete(handler: args.responseHandler, successAction: args.successAction,
                                failureAction: args.failureAction, task: task)
    }

    private func downloadOrResumeDidComplete(handler: NWApiDownloadResponseHandler, successAction: DownloadSuccessAction?,
                                             failureAction: DownloadFailureAction?, task: URLSessionTask?) {
        let mSelf = self
        var error: Error? = dlError
        if error == nil {
            do {
                try handler.processResponse(task?.response as? HTTPURLResponse)
                if let desc = handler.responseBodyDescription {
                    logResponse({ () -> String in
                        return "DEVELOPMENT INFO:\n" + desc
                    }, category: .info, logTask: task)
                } else {
                    logResponse(nil, category: .info, logTask: task)
                }
                DispatchQueue.main.async {
                    _ = mSelf.requestDidFinish(nil)
                }
                if let action = successAction {
                    DispatchQueue.main.async {
                        action(mSelf, handler)
                    }
                }
            } catch (let err) {
                error = err
            }
        }
        if let err = error {
            logRequestFinish(error: err, category: .warning, logTask: task)
            DispatchQueue.main.async {
                if !mSelf.requestDidFinish(err), let action = failureAction {
                    action(mSelf, handler, err)
                }
            }
        }
        dlError = nil
    }

    private func downloadDidComplete(args: DownloadRequestArgument, task: URLSessionTask?) {
        downloadOrResumeDidComplete(handler: args.responseHandler, successAction: args.successAction,
                                    failureAction: args.failureAction, task: task)
    }

    private func resumeDidComplete(args: ResumeRequestArgument, task: URLSessionTask?) {
        downloadOrResumeDidComplete(handler: args.responseHandler, successAction: args.successAction,
                                    failureAction: args.failureAction, task: task)
    }

    func didComplete(_ error: Error?) {
        let mSelf = self
        let tsk = task
        queue.addOperation {
            mSelf.state = .finished
            if let err = error {
                mSelf.finishRequest(with: err, logCategory: .warning, task: tsk)
            } else {
                switch mSelf.taskType {
                case .data(let args):
                    mSelf.dataDidComplete(args: args, task: tsk)
                case .download(let args):
                    mSelf.downloadDidComplete(args: args, task: tsk)
                case .resume(let args):
                    mSelf.resumeDidComplete(args: args, task: tsk)
                case .upload(let args):
                    if let file = mSelf.uploadFile {
                        try? FileManager.default.removeItem(atPath: file)
                    }
                    mSelf.uploadDidComplete(args: args, task: tsk)
                }
            }
        }
    }

    func didSendBodyData(bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let action = sendingProgressAction else { return }
        let mSelf = self
        queue.addOperation {
            var instSpeed = 0.0
            var avgSpeed = 0.0
            let now = Date()
            if let last = mSelf.lastDate {
                instSpeed = Double(bytesSent) / now.timeIntervalSince(last)
            }
            mSelf.lastDate = now
            if let start = mSelf.startingDate {
                avgSpeed = Double(totalBytesSent) / now.timeIntervalSince(start)
            }
            DispatchQueue.main.async {
                action(bytesSent, totalBytesSent, totalBytesExpectedToSend, instSpeed, avgSpeed)
            }
        }
    }

    func didFinishDownloading(_ location: URL) {
        switch taskType {
        case .download(let args):
            do {
                try args.responseHandler.processTempFile(location)
            } catch (let err) {
                dlError = err
            }
        default:
            break
        }
    }

    func didWriteData(bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let action = downloadProgressAction else { return }
        let mSelf = self
        queue.addOperation {
            mSelf.state = .receiving
            var instSpeed = 0.0
            var avgSpeed = 0.0
            let now = Date()
            if let last = mSelf.lastDate {
                instSpeed = Double(bytesWritten) / now.timeIntervalSince(last)
            }
            mSelf.lastDate = now
            if let start = mSelf.startingDate {
                avgSpeed = Double(totalBytesWritten) / now.timeIntervalSince(start)
            }
            DispatchQueue.main.async {
                action(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite, instSpeed, avgSpeed)
            }
        }
    }

}
