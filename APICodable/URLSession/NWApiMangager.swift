//
//  NWApiMangager.swift
//
//  Created by DươngPQ on 21/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation
import CommonLog

/// API Requests manager
public class NWApiManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {

    public static let kDefaultSessionName = "API.URLSession.Default"
    public static let shared = NWApiManager()
    
    // MARK: - Request sessions

    private let requestOperationQueue = OperationQueue()
    private var sessions = [String: URLSession]()
    private var requests = [String: [NWApiRequest]]()
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

    func registRequest(request: NWApiRequest, session: String) {
        requestOperationQueue.addOperation {
            var array = NWApiManager.shared.requests[session] ?? []
            array.append(request)
            NWApiManager.shared.requests[session] = array
        }
    }

    func getSession(_ name: String) -> URLSession? {
        return sessions[name]
    }

    func cancelRequest(request: NWApiRequest, task: URLSessionTask, completion: @escaping (Data?) -> Void) {
        requestOperationQueue.addOperation {
            for (session, var array) in NWApiManager.shared.requests {
                var found = false
                for (index, item) in array.enumerated() where item === request {
                    array.remove(at: index)
                    NWApiManager.shared.requests[session] = array
                    found = true
                    break
                }
                if found { break }
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
        CMLog("AUTHENTICATION type \(challenge.protectionSpace.authenticationMethod)", challenge.protectionSpace,
            category: .warning, group: NWLogGroup)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let hosts = trustedHosts, hosts.contains(challenge.protectionSpace.host),
            let trust = challenge.protectionSpace.serverTrust {
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
            var sessName = ""
            for (name, curSession) in sessions where curSession === session {
                sessName = name
                break
            }
            let array = requests[sessName] ?? []
            for request in array {
                request.isAuthenticationFailed = true
            }
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func findRequest(with task: URLSessionTask) -> NWApiRequest? {
        for array in requests.values {
            for request in array where task === request.task {
                return request
            }
        }
        return nil
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        findRequest(with: dataTask)?.didReceive(response: response, completion: completionHandler)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        findRequest(with: dataTask)?.didReceive(data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        for (name, var array) in requests {
            var found = false
            for (idx, request) in array.enumerated() where task === request.task {
                request.didComplete(error)
                request.task = nil
                array.remove(at: idx)
                requests[name] = array
                found = true
                break
            }
            if found { break }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        findRequest(with: task)?.didSendBodyData(bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        findRequest(with: downloadTask)?.didFinishDownloading(location)
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        findRequest(with: downloadTask)?.didWriteData(bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

}
