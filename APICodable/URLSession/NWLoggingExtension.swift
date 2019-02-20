//
//  NWLogging.swift
//
//  Created by DươngPQ on 29/01/2019.
//

import Foundation

func NWGetRequestDescription(request: URLRequest, bodyDesc: String?) -> String {
    var result = "REQUEST START:\n"
    if let url = request.url {
        result += "URL: " + url.absoluteString + "\n"
    }
    if let method = request.httpMethod {
        result += "METHOD: " + method + "\n"
    }
    var encoding = String.Encoding.utf8
    var isJson = false
    if let header = request.allHTTPHeaderFields, header.count > 0 {
        result += "HEADERS:\n" + NWGetDictionaryDescription(header) + "\n"
        if let contentTypeRaw = header[HTTPRequestHeaderField.contentType.value],
            let contentType = try? NWContentType(httpContentType: contentTypeRaw) {
            let params = contentType.getValueAndParameters()
            if params.0.lowercased() == (NWContentType.MainType.application.value + "/" + NWContentType.MainType.ApplicationSubType.json) {
                isJson = true
            }
            if let encodingName = params.1?[NWContentType.MainType.TextSubType.paramCharset] {
                encoding = String.Encoding(httpCharset: encodingName)
            }
        }
    }
    if let desc = bodyDesc {
        if let body = request.httpBody {
            result += "BODY (\(body.count) bytes):\n" + desc
        } else {
            result += "BODY:\n" + desc
        }
    } else if let body = request.httpBody {
        if isJson, let jsonObj = try? JSONSerialization.jsonObject(with: body, options: []),
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted]),
            let jsonStr = String(data: jsonData, encoding: .utf8) {
            result += "BODY (JSON \(body.count) bytes):\n" + jsonStr
        } else if let str = String(data: body, encoding: encoding) {
            result += "BODY (\(body.count) bytes):\n" + str
        } else {
            result += "BODY (\(body.count) bytes):\n〈Binary data〉"
        }
    }
    return result.trimmingCharacters(in: CharacterSet.newlines)
}

func NWGetResponseDescription(task: URLSessionTask?, data: Data?) -> String {
    var result = "REQUEST FINISH:\n"
    if let tsk = task, let response = tsk.response as? HTTPURLResponse {
        if let url = response.url {
            result += "URL: " + url.absoluteString + "\n"
        }
        result += "STATUS: \(response.statusCode)\n"
        var encoding = String.Encoding.utf8
        var isJson = false
        let header = response.allHeaderFields
        result += "HEADERS:\n" + NWGetDictionaryDescription(header) + "\n"
        if let contentTypeRaw = header[HTTPRequestHeaderField.contentType.value] as? String,
            let contentType = try? NWContentType(httpContentType: contentTypeRaw) {
            let params = contentType.getValueAndParameters()
            if params.0.lowercased() == (NWContentType.MainType.application.value + "/" + NWContentType.MainType.ApplicationSubType.json) {
                isJson = true
            }
            if let encodingName = params.1?[NWContentType.MainType.TextSubType.paramCharset] {
                encoding = String.Encoding(httpCharset: encodingName)
            }
        }
        if let dat = data {
            if isJson, let jsonObj = try? JSONSerialization.jsonObject(with: dat, options: []),
                let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted]),
                let jsonStr = String(data: jsonData, encoding: .utf8) {
                result += "BODY (JSON \(dat.count) bytes):\n" + jsonStr
            } else if let str = String(data: dat, encoding: encoding) {
                result += "BODY (\(dat.count) bytes):\n" + str
            } else {
                result += "BODY (\(dat.count) bytes):\n〈Binary data〉"
            }
        }
    }
    return result.trimmingCharacters(in: CharacterSet.newlines)
}
