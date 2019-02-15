//
//  NWLogging.swift
//
//  Created by DươngPQ on 29/01/2019.
//

import Foundation

public var NWLogIndent = "  "

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

private func NWShiftDescription(_ desc: String) -> String {
    let padding = "\n\(NWLogIndent)"
    var result = desc.replacingOccurrences(of: "\n", with: padding)
    if result.count >= padding.count {
        let index = result.index(result.endIndex, offsetBy: -padding.count)
        if String(result[index...]) == padding {
            result = String(result[..<index]) + "\n"
        }
    }
    return NWLogIndent + result
}

public func NWGetDescription(_ object: Any?) -> String {
    if object == nil {
        return "〈nil〉"
    }
    if object is NSNull {
        return "〈NSNull〉"
    }
    if let number = object as? NSNumber {
        if NSStringFromClass(number.classForCoder) == "__NSCFBoolean" {
            return number.boolValue ? "〈true〉" : "〈false〉"
        }
        return "\(number)"
    }
    if let error = object as? NSError {
        var result = "ERROR: domain=\"\(error.domain)\"; code=\(error.code); \"\(error.localizedDescription)\""
        if error.userInfo.count > 0 {
            result += "; UserInfo:\n" + NWShiftDescription(NWGetDictionaryDescription(error.userInfo))
        }
        return result
    }
    if let data = object as? Data {
        return "DATA: \(data.count) bytes"
    }
    if let str = object as? String {
        return "\"\(str)\""
    }
    if let dic = object as? [AnyHashable: Any] {
        return NWGetDictionaryDescription(dic)
    }
    if let array = object as? [Any] {
        return NWGetArrayDescription(array)
    }
    if let obj = object as? NSObject {
        return obj.description
    }
    return "\(object!)"
}

public func NWGetDictionaryDescription(_ dic: [AnyHashable: Any]) -> String {
    if dic.count == 0 {
        return "〈0〉{}"
    }
    var result = "〈\(dic.count)〉{\n"
    for (key, value) in dic {
        result += NWShiftDescription("\(key) ＝ \(NWGetDescription(value))") + ";\n"
    }
    result += "}"
    return result
}

public func NWGetArrayDescription(_ array: [Any]) -> String {
    if array.count == 0 {
        return "〈0〉[]"
    }
    var result = "〈\(array.count)〉[\n"
    for item in array {
        result += NWShiftDescription(NWGetDescription(item)) + ",\n"
    }
    result = String(result[..<result.index(result.endIndex, offsetBy: -2)]) + "\n]"
    return result
}

public protocol NWLoggerClient: class {
    func log(data: String, catgory: NWLogger.LogCategory?, group: String?, date: Date, functionName: String,
             fileName: String, lineNum: Int, process: ProcessInfo, thread: mach_port_t, isMainThread: Bool)
}

/** Logger
 - Format:
 ```
 📌[Group]Category Date Time [processName:processId:threadId(m: main thread)] File [Line] Function
 Contents
 🏁
 ```
 - **Group** & **Category** may be not available.
 - Logs with **group** or **category** contained in *disabledGroup* / *disabledCategory* are ignored.
 - Content items are separated by *separator*
 */
public class NWLogger {

    public static let shared = NWLogger()

    /// How logging works
    public enum LogType {
        /// Not log
        case none
        /// Logging runs in request thread
        case sync
        /// Logging runs in custom thread
        case async(OperationQueue)
        /// Logging runs in main thread
        case main
    }

    public struct LogCategory: NWRawDataContainer {

        public let value: String

        public init(_ raw: ValueType) {
            value = raw
        }
        public static let info = LogCategory("💬")
        public static let warning = LogCategory("⚠️")
        public static let critical = LogCategory("❌")
    }

    public var logDateFormat = "y-MM-dd HH:mm:ss.SSS"
    public var dateFormatter: DateFormatter = {
        let result = DateFormatter()
        result.locale = Locale.current
        result.timeZone = TimeZone.current
        result.calendar = Calendar.current
        return result
    }()
    public var separator = "\n"
    private let logQueue: OperationQueue
    public var logType: LogType
    public var disabledGroup = [String]()
    public var disabledCategory = [LogCategory]()
    public var clients = [NWLoggerClient]()

    private init() {
        logQueue = OperationQueue()
        logQueue.maxConcurrentOperationCount = 1
        logType = .async(logQueue)
    }

    private func doLog(data: [Any?], category: LogCategory?, group: String?, date: Date, threadId: mach_port_t,
                       isMain: Bool, process: ProcessInfo, functionName: String, fileName: String, lineNum: Int) {
        var result = "📌"
        if let grp = group {
            if disabledGroup.contains(grp) { return }
            result += "[\(grp)]"
        }
        if let cat = category {
            if disabledCategory.contains(cat) { return }
            result += cat.value
        }

        dateFormatter.dateFormat = logDateFormat
        result += " " + dateFormatter.string(from: date) + " [\(process.processName):\(process.processIdentifier):\(threadId)\(isMain ? "(m)" : "")]"
        result += " " + (fileName as NSString).lastPathComponent + " [\(lineNum)] " + functionName

        var content = ""
        if data.count > 0 {
            for item in data {
                if let str = item as? String {
                    content += str + separator
                } else {
                    content += NWGetDescription(item) + separator
                }
            }
            content = String(content[..<content.index(content.endIndex, offsetBy: -separator.count)])
        }

        result += "\n" + content + "\n🏁"
        print(result)
        for client in clients {
            client.log(data: content, catgory: category, group: group, date: date, functionName: functionName,
                       fileName: fileName, lineNum: lineNum, process: process, thread: threadId, isMainThread: isMain)
        }
    }

    fileprivate func log(data: [Any?], category: LogCategory?, group: String?, date: Date,
                     functionName: String, fileName: String, lineNum: Int) {
        let threadId = pthread_mach_thread_np(pthread_self())
        let isMain = Thread.isMainThread
        let process = ProcessInfo.processInfo
        switch logType {
        case .sync:
            doLog(data: data, category: category, group: group, date: date, threadId: threadId,
                  isMain: isMain, process: process, functionName: functionName, fileName: fileName, lineNum: lineNum)
        case .main:
            DispatchQueue.main.async {
                NWLogger.shared.doLog(data: data, category: category, group: group, date: date,
                                      threadId: threadId, isMain: isMain, process: process,
                                      functionName: functionName, fileName: fileName, lineNum: lineNum)
            }
        case .async(let queue):
            queue.addOperation {
                NWLogger.shared.doLog(data: data, category: category, group: group, date: date,
                                      threadId: threadId, isMain: isMain, process: process,
                                      functionName: functionName, fileName: fileName, lineNum: lineNum)
            }
        case .none:
            break
        }
    }

    fileprivate func log(block: @escaping () -> String, category: LogCategory?, group: String?, date: Date,
                     functionName: String, fileName: String, lineNum: Int) {
        let threadId = pthread_mach_thread_np(pthread_self())
        let isMain = Thread.isMainThread
        let process = ProcessInfo.processInfo
        switch logType {
        case .sync:
            doLog(data: [block()], category: category, group: group, date: date, threadId: threadId,
                  isMain: isMain, process: process, functionName: functionName, fileName: fileName, lineNum: lineNum)
        case .main:
            DispatchQueue.main.async {
                NWLogger.shared.doLog(data: [block()], category: category, group: group, date: date,
                                      threadId: threadId, isMain: isMain, process: process,
                                      functionName: functionName, fileName: fileName, lineNum: lineNum)
            }
        case .async(let queue):
            queue.addOperation {
                NWLogger.shared.doLog(data: [block()], category: category, group: group, date: date,
                                      threadId: threadId, isMain: isMain, process: process,
                                      functionName: functionName, fileName: fileName, lineNum: lineNum)
            }
        case .none:
            break
        }
    }

}

public func NWLog(_ data: Any?..., category: NWLogger.LogCategory? = nil, group: String? = nil, date: Date = Date(),
                  functionName: String = #function, fileName: String = #file, lineNum: Int = #line) {
    NWLogger.shared.log(data: data, category: category, group: group, date: date, functionName: functionName, fileName: fileName, lineNum: lineNum)
}

public func NWLog(block: @escaping () -> String, category: NWLogger.LogCategory? = nil, group: String? = nil,
                  date: Date = Date(), functionName: String = #function, fileName: String = #file, lineNum: Int = #line) {
    NWLogger.shared.log(block: block, category: category, group: group, date: date, functionName: functionName, fileName: fileName, lineNum: lineNum)
}
