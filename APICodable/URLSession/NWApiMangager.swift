//
//  NWApiMangager.swift
//
//  Created by DươngPQ on 21/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// API Requests manager
public class NWApiManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {

    public static let kDefaultSessionName = "API.URLSession.Default"
    public static let shared = NWApiManager()
    
    // MARK: - Request sessions

    private let requestOperationQueue = OperationQueue()
    private var sessions = [String: URLSession]()
    private var requests = [NWApiRequest]()
    public var trustedHosts: [String]?
    public var username: String?
    public var password: String?
    public var authenticationHandler: ((String, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?

    /// Create `URLSession` with geven `configuration` and set for given `key`. If `configuration` is nil, remove `URLSession` if it exists.
    public func setSession(configuration: URLSessionConfiguration?, for key: String) {
        if let config = configuration {
            let session = URLSession(configuration: config, delegate: self, delegateQueue: requestOperationQueue)
            sessions[key] = session
        } else {
            _ = sessions.removeValue(forKey: key)
        }
    }

    // MARK: - Init

    private override init() {
        requestOperationQueue.maxConcurrentOperationCount = 1
        super.init()
        let configuration = URLSessionConfiguration.default
        setSession(configuration: configuration, for: NWApiManager.kDefaultSessionName)
    }

    func registRequest(_ request: NWApiRequest) {
        requestOperationQueue.addOperation {
            NWApiManager.shared.requests.append(request)
        }
    }

    func getSession(_ name: String) -> URLSession? {
        return sessions[name]
    }

    func cancelRequest(request: NWApiRequest, task: URLSessionTask, completion: @escaping (Data?) -> Void) {
        requestOperationQueue.addOperation {
            for (index, item) in NWApiManager.shared.requests.enumerated() where item === request {
                NWApiManager.shared.requests.remove(at: index)
                break
            }
            if let dlTask = task as? URLSessionDownloadTask {
                dlTask.cancel(byProducingResumeData: { (data) in
                    completion(data)
                })
            } else {
                task.cancel()
                completion(nil)
            }
        }
    }

    // MARK: - URL Session delegate

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let hosts = trustedHosts, hosts.contains(challenge.protectionSpace.host), let trust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic,
            let uname = username, let pass = password {
            let credential = URLCredential(user: uname, password: pass, persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else if let action = authenticationHandler {
            var key = ""
            for (sKey, sValue) in sessions where session === sValue {
                key = sKey
                break
            }
            action(key, challenge, completionHandler)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        for request in requests where dataTask === request.task {
            request.didReceive(response: response, completion: completionHandler)
            break
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        for request in requests where dataTask === request.task {
            request.didReceive(data)
            break
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var index: Int? = nil
        for (idx, request) in requests.enumerated() where task === request.task {
            request.didComplete(error)
            request.task = nil
            index = idx
            break
        }
        if let idx = index {
            requests.remove(at: idx)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        for request in requests where task === request.task {
            request.didSendBodyData(bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
            break
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        for request in requests where downloadTask === request.task {
            request.didFinishDownloading(location)
            break
        }
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        for request in requests where downloadTask === request.task {
            request.didWriteData(bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            break
        }
    }

}
