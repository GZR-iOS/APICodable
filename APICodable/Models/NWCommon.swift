//
//  NWCommon.swift
//
//  Created by DươngPQ on 08/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

public protocol NWErrorType: LocalizedError {}

extension NWErrorType {

    public var errorDescription: String? {
        return "\(self)"
    }

}

public enum NWError: NWErrorType {
    case notSupport
    case encoding // failed to encode data with given string encoding
    case parameterNotEncodable
}
public let NWCRLF = "\r\n"
public let NWHTTPVersion = "1.1"
public var NWLogGroup = "🌏"

// MARK: -

public protocol NWRawDataContainer: Hashable {

    associatedtype ValueType: Hashable

    var value: ValueType { get }
    init(_ raw: ValueType)

}

public extension NWRawDataContainer {

    func hash(into hasher: inout Hasher) {
        value.hash(into: &hasher)
    }

    var hashValue: Int {
        return value.hashValue
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }

}

// https://tools.ietf.org/html/rfc2616

/**
 HTTP/1.1 clients and servers that parse the date value MUST accept
 all three formats (for compatibility with HTTP/1.0), though they MUST
 only generate the RFC 1123 format for representing HTTP-date values
 in header fields. See section 19.3 for further information.

 All HTTP date/time stamps MUST be represented in Greenwich Mean Time
 (GMT), without exception. For the purposes of HTTP, GMT is exactly
 equal to UTC (Coordinated Universal Time). This is indicated in the
 first two formats by the inclusion of "GMT" as the three-letter
 abbreviation for time zone, and MUST be assumed when reading the
 asctime format. HTTP-date is public static let sensitive and MUST NOT include
 additional LWS beyond that specifically included as SP in the
 grammar.

 HTTP-date    = rfc1123-date | rfc850-date | asctime-date
 rfc1123-date = wkday "," SP date1 SP time SP "GMT"
 rfc850-date  = weekday "," SP date2 SP time SP "GMT"
 asctime-date = wkday SP date3 SP time SP 4DIGIT
 date1        = 2DIGIT SP month SP 4DIGIT
                ; day month year (e.g., 02 Jun 1982)
 date2        = 2DIGIT "-" month "-" 2DIGIT
                ; day-month-year (e.g., 02-Jun-82)
 date3        = month SP ( 2DIGIT | ( SP 1DIGIT ))
 ; month day (e.g., Jun  2)
 time         = 2DIGIT ":" 2DIGIT ":" 2DIGIT
                ; 00:00:00 - 23:59:59
 wkday        = "Mon" | "Tue" | "Wed"
                | "Thu" | "Fri" | "Sat" | "Sun"
 weekday      = "Monday" | "Tuesday" | "Wednesday"
                | "Thursday" | "Friday" | "Saturday" | "Sunday"
 month        = "Jan" | "Feb" | "Mar" | "Apr"
                | "May" | "Jun" | "Jul" | "Aug"
                | "Sep" | "Oct" | "Nov" | "Dec"
 */
public struct HTTPDateTimeFormat: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    /// The first format is preferred as an Internet standard and represents a fixed-length subset of that defined by RFC 1123 [8] (an update to RFC 822 [9]).
    public static let rfc1123 = HTTPDateTimeFormat("E, dd MMM yyyy HH:mm:ss z")
    /// The second format is in common use, but is based on the obsolete RFC 850 [12] date format and lacks a four-digit year.
    public static let rfc1036 = HTTPDateTimeFormat("EEEE, dd-MMM-yy HH:mm:ss z")
    public static let asctime = HTTPDateTimeFormat("E MMM d HH:mm:ss yyyy")

    public func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = self.value
        return formatter.string(from: date)
    }

}

// MARK: -

/// Content coding values indicate an encoding transformation that has been or can be applied to an entity.
public struct HTTPContentCoding: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    /// An encoding format produced by the file compression program "gzip" (GNU zip) as described in RFC 1952 [25]. This format is a Lempel-Ziv coding (LZ77) with a 32 bit CRC.
    public static let gzip = HTTPContentCoding("gzip")
    /// The encoding format produced by the common UNIX file compression program "compress". This format is an adaptive Lempel-Ziv-Welch coding (LZW).
    public static let compress = HTTPContentCoding("compress")
    /// The "zlib" format defined in RFC 1950 [31] in combination with the "deflate" compression mechanism described in RFC 1951 [29].
    public static let deflate = HTTPContentCoding("deflate")
    /// The default (identity) encoding; the use of no transformation whatsoever. This content-coding is used only in the Accept- Encoding header, and SHOULD NOT be used in the Content-Encoding header.
    public static let identity = HTTPContentCoding("identity")

}

// MARK: -

public struct HTTPMethod: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    public static let get = HTTPMethod("GET")
    public static let head = HTTPMethod("HEAD")
    public static let post = HTTPMethod("POST")
    public static let put = HTTPMethod("PUT")
    public static let delete = HTTPMethod("DELETE")
    public static let trace = HTTPMethod("TRACE")
    public static let connect = HTTPMethod("CONNECT")

}

// MARK: -

public struct HTTPStatusCode: NWRawDataContainer {

    public let value: Int

    public init(_ raw: Int) {
        value = raw
    }

    /// 100 - The client SHOULD continue with its request.
    public static let continue_100 = HTTPStatusCode(100)
    /// 101 - The server understands and is willing to comply with the client’s request, via the Upgrade message header field (section 14.42), for a change in the application protocol being used on this connection. The server will switch protocols to those defined by the response’s Upgrade header field immediately after the empty line which terminates the 101 response.
    public static let switchingProtocols_101 = HTTPStatusCode(101)
    /// 200 - The request has succeeded.
    public static let ok_200 = HTTPStatusCode(200)
    /// 201 - The request has been fulfilled and resulted in a new resource being created.
    public static let created_201 = HTTPStatusCode(201)
    /// 202 - The request has been accepted for processing, but the processing has not been completed.
    public static let accepted_202 = HTTPStatusCode(202)
    /// 203 - The returned metainformation in the entity-header is not the definitive set as available from the origin server, but is gathered from a local or a third-party copy.
    public static let nonAuthoritativeInformation_203 = HTTPStatusCode(203)
    /// 204 - The server has fulfilled the request but does not need to return an entity-body, and might want to return updated metainformation.
    public static let noContent_204 = HTTPStatusCode(204)
    /// 205 - The server has fulfilled the request and the user agent SHOULD reset the document view which caused the request to be sent.
    public static let resetContent_205 = HTTPStatusCode(205)
    /// 206 - The server has fulfilled the partial GET request for the resource.
    public static let partialContent_206 = HTTPStatusCode(206)
    /// 300 - The requested resource corresponds to any one of a set of representations, each with its own specific location, and agent-driven negotiation information (section 12) is being provided so that the user (or user agent) can select a preferred representation and redirect its request to that location.
    public static let multipleChoices_300 = HTTPStatusCode(300)
    /// 301 - The requested resource has been assigned a new permanent URI and any future references to this resource SHOULD use one of the returned URIs.
    public static let movedPermanently_301 = HTTPStatusCode(301)
    /// 302 - The requested resource resides temporarily under a different URI.
    public static let found_302 = HTTPStatusCode(302)
    /// 303 - The response to the request can be found under a different URI and SHOULD be retrieved using a GET method on that resource.
    public static let seeOther_303 = HTTPStatusCode(303)
    /// 304 - If the client has performed a conditional GET request and access is allowed, but the document has not been modified, the server SHOULD respond with this status code.
    public static let notModified_304 = HTTPStatusCode(304)
    /// 305 - The requested resource MUST be accessed through the proxy given by the Location field.
    public static let useProxy_305 = HTTPStatusCode(305)
    /// 307 - The requested resource resides temporarily under a different URI.
    public static let temporaryRedirect_307 = HTTPStatusCode(307)
    /// 400 - The request could not be understood by the server due to malformed syntax.
    public static let badRequest_400 = HTTPStatusCode(400)
    /// 401 - The request requires user authentication.
    public static let unauthorized_401 = HTTPStatusCode(401)
    /// 402 - This code is reserved for future use.
    public static let paymentRequired_402 = HTTPStatusCode(402)
    /// 403 - The server understood the request, but is refusing to fulfill it. Authorization will not help and the request SHOULD NOT be repeated.
    public static let forbidden_403 = HTTPStatusCode(403)
    /// 404 - The server has not found anything matching the Request-URI.
    public static let notFound_404 = HTTPStatusCode(404)
    /// 405 - The method specified in the Request-Line is not allowed for the resource identified by the Request-URI.
    public static let methodNotAllowed_405 = HTTPStatusCode(405)
    /// 406 - The resource identified by the request is only capable of generating response entities which have content characteristics not acceptable according to the accept headers sent in the request.
    public static let notAcceptable_406 = HTTPStatusCode(406)
    /// 407 - This code is similar to 401 (Unauthorized), but indicates that the client must first authenticate itself with the proxy.
    public static let proxyAuthenticationRequired_407 = HTTPStatusCode(407)
    /// 408 - The client did not produce a request within the time that the server was prepared to wait.
    public static let requestTimeout_408 = HTTPStatusCode(408)
    /// 409 - The request could not be completed due to a conflict with the current state of the resource.
    public static let conflict_409 = HTTPStatusCode(409)
    /// 410 - The requested resource is no longer available at the server and no forwarding address is known.
    public static let gone_410 = HTTPStatusCode(410)
    /// 411 - The server refuses to accept the request without a definedContent-Length.
    public static let lengthRequired_411 = HTTPStatusCode(411)
    /// 412 - The precondition given in one or more of the request-header fields evaluated to false when it was tested on the server.
    public static let preconditionFailed_412 = HTTPStatusCode(412)
    /// 413 - The server is refusing to process a request because the request entity is larger than the server is willing or able to process.
    public static let requestEntityTooLarge_413 = HTTPStatusCode(413)
    /// 414 - The server is refusing to service the request because the Request-URI is longer than the server is willing to interpret.
    public static let requestURITooLong_414 = HTTPStatusCode(414)
    /// 415 - The server is refusing to service the request because the entity of the request is in a format not supported by the requested resource for the requested method.
    public static let unsupportedMediaType_415 = HTTPStatusCode(415)
    /// 416 - A server SHOULD return a response with this status code if a request included a Range request-header field (section 14.35) , and none of the range-specifier values in this field overlap the current extent of the selected resource, and the request did not include an If-Range request-header field.
    public static let requestedRangeNotSatisfiable_416 = HTTPStatusCode(416)
    /// 417 - The expectation given in an Expect request-header field (see section 14.20) could not be met by this server, or, if the server is a proxy, the server has unambiguous evidence that the request could not be met by the next-hop server.
    public static let expectationFailed_417 = HTTPStatusCode(417)
    /// 500 - The server encountered an unexpected condition which prevented it from fulfilling the request.
    public static let internalServerError_500 = HTTPStatusCode(500)
    /// 501 - The server does not support the functionality required to fulfill the request.
    public static let notImplemented_501 = HTTPStatusCode(501)
    /// 502 - The server, while acting as a gateway or proxy, received an invalid response from the upstream server it accessed in attempting to fulfill the request.
    public static let badGateway_502 = HTTPStatusCode(502)
    /// 503 - The server is currently unable to handle the request due to a temporary overloading or maintenance of the server.
    public static let serviceUnavailable_503 = HTTPStatusCode(503)
    /// 504 - The server, while acting as a gateway or proxy, did not receive a timely response from the upstream server specified by the URI (e.g. HTTP, FTP, LDAP) or some other auxiliary server (e.g. DNS) it needed to access in attempting to complete the request.
    public static let gatewayTimeout_504 = HTTPStatusCode(504)
    /// 505 - The server does not support, or refuses to support, the HTTP protocol version that was used in the request message.
    public static let httpVersionNotSupported_505 = HTTPStatusCode(505)

}

// MARK: -

public struct HTTPRequestHeaderField: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    /// The `Accept` request-header field can be used to specify certain media types which are acceptable for the response.
    public static let accept = HTTPRequestHeaderField("Accept")
    /// The `Accept-Charset` request-header field can be used to indicate what character sets are acceptable for the response.
    public static let acceptCharset = HTTPRequestHeaderField("Accept-Charset")
    /// The `Accept-Encoding` request-header field is similar to Accept, but restricts the content-codings (section 3.5) that are acceptable in the response.
    public static let acceptEncoding = HTTPRequestHeaderField("Accept-Encoding")
    /// The `Accept-Language` request-header field is similar to Accept, but restricts the set of natural languages that are preferred as a response to the request.
    public static let acceptLanguage = HTTPRequestHeaderField("Accept-Language")
    /// The `Allow` entity-header field lists the set of methods supported by the resource identified by the Request-URI.
    public static let allow = HTTPRequestHeaderField("Allow")
    /// A user agent that wishes to authenticate itself with a server--usually, but not necessarily, after receiving a 401 response--does so by including an `Authorization` request-header field with the request.
    public static let authorization = HTTPRequestHeaderField("Authorization")
    /// The `Cache-Control` general-header field is used to specify directives that MUST be obeyed by all caching mechanisms along the request/response chain.
    public static let cacheControl = HTTPRequestHeaderField("Cache-Control")
    /// The `Connection` general-header field allows the sender to specify options that are desired for that particular connection and MUST NOT be communicated by proxies over further connections.
    public static let connection = HTTPRequestHeaderField("Connection")
    /// The `Content-Encoding` entity-header field is used as a modifier to the media-type.
    public static let contentEncoding = HTTPRequestHeaderField("Content-Encoding")
    /// The `Content-Language` entity-header field describes the natural language(s) of the intended audience for the enclosed entity.
    public static let contentLanguage = HTTPRequestHeaderField("Content-Language")
    /// The `Content-Length` entity-header field indicates the size of the entity-body, in decimal number of OCTETs, sent to the recipient or, in the case of the HEAD method, the size of the entity-body that would have been sent had the request been a GET.
    public static let contentLength = HTTPRequestHeaderField("Content-Length")
    /// The `Content-Location` entity-header field MAY be used to supply the resource location for the entity enclosed in the message when that entity is accessible from a location separate from the requested resource’s URI.
    public static let contentLocation = HTTPRequestHeaderField("Content-Location")
    /// The `Content-MD5` entity-header field, as defined in RFC 1864 [23], is an MD5 digest of the entity-body for the purpose of providing an end-to-end message integrity check (MIC) of the entity-body.
    public static let contentMD5 = HTTPRequestHeaderField("Content-MD5")
    /// The `Content-Range` entity-header is sent with a partial entity-body to specify where in the full entity-body the partial body should be applied.
    public static let contentRange = HTTPRequestHeaderField("Content-Range")
    /// The `Content-Type` entity-header field indicates the media type of the entity-body sent to the recipient or, in the case of the HEAD method, the media type that would have been sent had the request been a GET.
    public static let contentType = HTTPRequestHeaderField("Content-Type")
    /// The `Date` general-header field represents the date and time at which the message was originated, having the same semantics as orig-date in RFC 822.
    public static let date = HTTPRequestHeaderField("Date")
    /// The `Expect` request-header field is used to indicate that particular server behaviors are required by the client.
    public static let expect = HTTPRequestHeaderField("Expect")
    /// The `Expires` entity-header field gives the date/time after which the response is considered stale.
    public static let expires = HTTPRequestHeaderField("Expires")
    /// The `From` request-header field, if given, SHOULD contain an Internet e-mail address for the human user who controls the requesting user agent.
    public static let from = HTTPRequestHeaderField("From")
    /// The `Host` request-header field specifies the Internet host and port number of the resource being requested, as obtained from the original URI given by the user or referring resource (generally an HTTP URL, as described in section 3.2.2).
    public static let host = HTTPRequestHeaderField("Host")
    /// The `If-Match` request-header field is used with a method to make it conditional.
    public static let ifMatch = HTTPRequestHeaderField("If-Match")
    /// The `If-Modified-Since` request-header field is used with a method to make it conditional: if the requested variant has not been modified since the time specified in this field, an entity will not be returned from the server; instead, a 304 (not modified) response will be returned without any message-body.
    public static let ifModifiedSince = HTTPRequestHeaderField("If-Modified-Since")
    /// The `If-None-Match` request-header field is used with a method to make it conditional.
    public static let ifNoneMatch = HTTPRequestHeaderField("If-None-Match")
    /// The `If-Range` header allows a client to “short-circuit” the second request.
    public static let ifRange = HTTPRequestHeaderField("If-Range")
    /// The `If-Unmodified-Since` request-header field is used with a method to make it conditional.
    public static let ifUnmodifiedSince = HTTPRequestHeaderField("If-Unmodified-Since")
    /// The `Last-Modified` entity-header field indicates the date and time at which the origin server believes the variant was last modified.
    public static let lastModified = HTTPRequestHeaderField("Last-Modified")
    /// The `Max-Forwards` request-header field provides a mechanism with the TRACE (section 9.8) and OPTIONS (section 9.2) methods to limit the number of proxies or gateways that can forward the request to the next inbound server.
    public static let maxForwards = HTTPRequestHeaderField("Max-Forwards")
    /// The `Pragma` general-header field is used to include implementation-specific directives that might apply to any recipient along the request/response chain.
    public static let pragma = HTTPRequestHeaderField("Pragma")
    /// The `Proxy-Authorization` request-header field allows the client to identify itself (or its user) to a proxy which requires authentication.
    public static let proxyAuthorization = HTTPRequestHeaderField("Proxy-Authorization")
    /// Byte range specifications in HTTP apply to the sequence of bytes in the entity-body
    public static let range = HTTPRequestHeaderField("Range")
    /// The `Referer`[sic] request-header field allows the client to specify, for the server’s benefit, the address (URI) of the resource from which the Request-URI was obtained (the “referrer”, although the header field is misspelled.)
    public static let referer = HTTPRequestHeaderField("Referer")
    /// The `TE` request-header field indicates what extension transfer-codings it is willing to accept in the response and whether or not it is willing to accept trailer fields in a chunked transfer-coding.
    public static let transferCoding = HTTPRequestHeaderField("TE")
    /// The `Trailer` general field value indicates that the given set of header fields is present in the trailer of a message encoded with chunked transfer-coding.
    public static let trailer = HTTPRequestHeaderField("Trailer")
    /// The `Transfer-Encoding` general-header field indicates what (if any) type of transformation has been applied to the message body in order to safely transfer it between the sender and the recipient.
    public static let transferEncoding = HTTPRequestHeaderField("Transfer-Encoding")
    /// The `Upgrade` general-header allows the client to specify what additional communication protocols it supports and would like to use if the server finds it appropriate to switch protocols.
    public static let upgrade = HTTPRequestHeaderField("Upgrade")
    /// The `User-Agent` request-header field contains information about the user agent originating the request.
    public static let userAgent = HTTPRequestHeaderField("User-Agent")
    /// The `Vary` field value indicates the set of request-header fields that fully determines, while the response is fresh, whether a cache is permitted to use the response to reply to a subsequent request without revalidation.
    public static let vary = HTTPRequestHeaderField("Vary")
    /// The `Via` general-header field MUST be used by gateways and proxies to indicate the intermediate protocols and recipients between the user agent and the server on requests, and between the origin server and the client on responses.
    public static let via = HTTPRequestHeaderField("Via")
    /// The `Warning` general-header field is used to carry additional information about the status or transformation of a message which might not be reflected in the message.
    public static let warning = HTTPRequestHeaderField("Warning")

    // From Wikipedia https://en.wikipedia.org/wiki/List_of_HTTP_header_fields
    /// Acceptable version in time
    public static let acceptDatetime = HTTPRequestHeaderField("Accept-Datetime")
    /// An HTTP cookie previously sent by the server with Set-Cookie
    public static let cookie = HTTPRequestHeaderField("Cookie")
    /// No description (Used in multipart)
    public static let contentDisposition = HTTPRequestHeaderField("Content-Disposition")

}

// MARK: -

public struct HTTPResponseHeaderField: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    /// The `Accept-Ranges` response-header field allows the server to indicate its acceptance of range requests for a resource
    public static let acceptRanges = HTTPResponseHeaderField("Accept-Ranges")
    /// The `Age` response-header field conveys the sender's estimate of the amount of time since the response (or its revalidation) was generated at the origin server.
    public static let age = HTTPResponseHeaderField("Age")
    /// The `Allow` entity-header field lists the set of methods supported by the resource identified by the Request-URI.
    public static let allow = HTTPResponseHeaderField("Allow")
    /// The `Cache-Control` general-header field is used to specify directives that MUST be obeyed by all caching mechanisms along the request/response chain.
    public static let cacheControl = HTTPResponseHeaderField("Cache-Control")
    /// The `Connection` general-header field allows the sender to specify options that are desired for that particular connection and MUST NOT be communicated by proxies over further connections.
    public static let connection = HTTPResponseHeaderField("Connection")
    /// The `Content-Encoding` entity-header field is used as a modifier to the media-type.
    public static let contentEncoding = HTTPResponseHeaderField("Content-Encoding")
    /// The `Content-Language` entity-header field describes the natural language(s) of the intended audience for the enclosed entity.
    public static let contentLanguage = HTTPResponseHeaderField("Content-Language")
    /// The `Content-Length` entity-header field indicates the size of the entity-body, in decimal number of OCTETs, sent to the recipient or, in the case of the HEAD method, the size of the entity-body that would have been sent had the request been a GET.
    public static let contentLength = HTTPResponseHeaderField("Content-Length")
    /// The `Content-Location` entity-header field MAY be used to supply the resource location for the entity enclosed in the message when that entity is accessible from a location separate from the requested resource’s URI.
    public static let contentLocation = HTTPResponseHeaderField("Content-Location")
    /// The `Content-MD5` entity-header field, as defined in RFC 1864 [23], is an MD5 digest of the entity-body for the purpose of providing an end-to-end message integrity check (MIC) of the entity-body.
    public static let contentMD5 = HTTPResponseHeaderField("Content-MD5")
    /// The `Content-Range` entity-header is sent with a partial entity-body to specify where in the full entity-body the partial body should be applied.
    public static let contentRange = HTTPResponseHeaderField("Content-Range")
    /// The `Content-Type` entity-header field indicates the media type of the entity-body sent to the recipient or, in the case of the HEAD method, the media type that would have been sent had the request been a GET.
    public static let contentType = HTTPResponseHeaderField("Content-Type")
    /// The `Date` general-header field represents the date and time at which the message was originated, having the same semantics as orig-date in RFC 822.
    public static let date = HTTPResponseHeaderField("Date")
    /// The `ETag` response-header field provides the current value of the entity tag for the requested variant.
    public static let etag = HTTPResponseHeaderField("ETag")
    /// The `Expires` entity-header field gives the date/time after which the response is considered stale.
    public static let expires = HTTPResponseHeaderField("Expires")
    /// The `Last-Modified` entity-header field indicates the date and time at which the origin server believes the variant was last modified.
    public static let lastModified = HTTPResponseHeaderField("Last-Modified")
    /// The `Location` response-header field is used to redirect the recipient to a location other than the Request-URI for completion of the request or identification of a new resource.
    public static let location = HTTPResponseHeaderField("Location")
    /// The `Pragma` general-header field is used to include implementation-specific directives that might apply to any recipient along the request/response chain.
    public static let pragma = HTTPResponseHeaderField("Pragma")
    /// The `Proxy-Authenticate` response-header field MUST be included as part of a 407 (Proxy Authentication Required) response.
    public static let proxyAuthenticate = HTTPResponseHeaderField("Proxy-Authenticate")
    /// Byte range specifications in HTTP apply to the sequence of bytes in the entity-body
    public static let range = HTTPResponseHeaderField("Range")
    /// The `Retry-After` response-header field can be used with a 503 (Service Unavailable) response to indicate how long the service is expected to be unavailable to the requesting client.
    public static let retryAfter = HTTPResponseHeaderField("Retry-After")
    /// The `Server` response-header field contains information about the software used by the origin server to handle the request.
    public static let server = HTTPResponseHeaderField("Server")
    /// The `Trailer` general field value indicates that the given set of header fields is present in the trailer of a message encoded with chunked transfer-coding.
    public static let trailer = HTTPResponseHeaderField("Trailer")
    /// The `Transfer-Encoding` general-header field indicates what (if any) type of transformation has been applied to the message body in order to safely transfer it between the sender and the recipient.
    public static let transferEncoding = HTTPResponseHeaderField("Transfer-Encoding")
    /// The `Upgrade` general-header allows the client to specify what additional communication protocols it supports and would like to use if the server finds it appropriate to switch protocols.
    public static let upgrade = HTTPResponseHeaderField("Upgrade")
    /// The `Via` general-header field MUST be used by gateways and proxies to indicate the intermediate protocols and recipients between the user agent and the server on requests, and between the origin server and the client on responses.
    public static let via = HTTPResponseHeaderField("Via")
    /// The `Warning` general-header field is used to carry additional information about the status or transformation of a message which might not be reflected in the message.
    public static let warning = HTTPResponseHeaderField("Warning")
    /// The `WWW-Authenticate` response-header field MUST be included in 401 (Unauthorized) response messages.
    public static let wwAuthenticate = HTTPResponseHeaderField("WWW-Authenticate")
    /// An opportunity to raise a "File Download" dialogue box for a known MIME type with binary format or suggest a filename for dynamic content. Quotes are necessary with special characters.
    public static let contentDisposition = HTTPResponseHeaderField("Content-Disposition")

    // From Wikipedia
    /// An HTTP cookie
    public static let setCookie = HTTPResponseHeaderField("Set-Cookie")

}

public struct URIScheme: NWRawDataContainer {

    public let value: String

    public init(_ raw: String) {
        value = raw
    }

    static let http = URIScheme("http")
    static let https = URIScheme("https")
    static let file = URIScheme("file")
    static let ftp = URIScheme("ftp")
    static let samba = URIScheme("smb")

}
