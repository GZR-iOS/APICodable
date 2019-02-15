//
//  NWRfc2046.swift
//
//  Created by DươngPQ on 16/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

// https://tools.ietf.org/html/rfc2045
// https://tools.ietf.org/html/rfc2046
// https://tools.ietf.org/html/rfc2047

public let NWMultipartBoundaryMin = 1
public let NWMultipartBoundaryMax = 70
public let NWMimeEncodedWordMaxLength = 75
public let NWMimeEspecialsCharacters = CharacterSet(charactersIn: "()<>@,;:\"/[]?.=")

open class NWABNFHeaderLine: NWHeaderLine {

    public init(key: String, value: String, comment: String?) {
        var bdy = value
        if let cmt = comment, cmt.count > 0 {
            bdy += "; " + cmt
        }
        super.init(key: key, value: bdy)
    }

    public func getValueAndParameters() -> (String, [String: String]?) {
        if let range = body.range(of: ";") {
            let val = String(body[..<range.lowerBound])
            let comment = String(body[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespaces)
            if comment.count > 0 {
                var result = [String: String]()
                let params = comment.components(separatedBy: " ")
                for param in params where param.count > 0 {
                    if let pRange = param.range(of: "=") {
                        let pKey = String(param[..<pRange.lowerBound])
                        let pVal = String(param[pRange.upperBound...])
                        result[pKey] = pVal
                    }
                }
                return (val, result)
            }
            return (val, nil)
        }
        return (body, nil)
    }

}

/// Not support non-ascii parameters
public class NWContentType: NWABNFHeaderLine {

    public enum ContentTypeError: NWErrorType {
        case invalidParameterName
        case invalidParameterValue
    }

    public struct MainType: NWRawDataContainer {

        public let value: String

        public init(_ raw: ValueType) {
            value = raw
        }

        public static let application = MainType("application")
        public static let text = MainType("text")
        public static let image = MainType("image")
        public static let audio = MainType("audio")
        public static let video = MainType("video")
        public static let message = MainType("message")
        public static let multipart = MainType("multipart")

        public struct ApplicationSubType {
            /// Atom feeds
            public static let atomXml = "atom+xml"
            /// ECMAScript/JavaScript; Defined in RFC 4329 (equivalent to application/javascript but with stricter processing rules)
            public static let emacScript = "ecmascript"
            /// EDI X12 data; Defined in RFC 1767
            public static let ediX12 = "EDI-X12"
            /// EDI EDIFACT data; Defined in RFC 1767
            public static let edifact = "EDIFACT"
            /// JavaScript Object Notation JSON; Defined in RFC 4627
            public static let json = "json"
            /// ECMAScript/JavaScript; Defined in RFC 4329 (equivalent to application/ecmascript but with looser processing rules) It is not accepted in IE 8 or earlier - text/javascript is accepted but it is defined as obsolete in RFC 4329. The "type" attribute of the <script> tag in HTML5 is optional. In practice, omitting the media type of JavaScript programs is the most interoperable solution, since all browsers have always assumed the correct default even before HTML5.
            public static let javaScript = "javascript"
            /// Arbitrary binary data.[6] Generally speaking this type identifies files that are not associated with a specific application. Contrary to past assumptions by software packages such as Apache this is not a type that should be applied to unknown files. In such a case, a server or application should not indicate a content type, as it may be incorrect, but rather, should omit the type in order to allow the recipient to guess the type.[7]
            public static let octetStream = "octet-stream"
            /// Ogg, a multimedia bitstream container format; Defined in RFC 5334
            public static let ogg = "ogg"
            /// Portable Document Format, PDF has been in use for document exchange on the Internet since 1993; Defined in RFC 3778
            public static let pdf = "pdf"
            /// PostScript; Defined in RFC 2046
            public static let postSrcipt = "postscript"
            /// Resource Description Framework; Defined by RFC 3870
            public static let rdfXml = "rdf+xml"
            /// RSS feeds
            public static let rssXml = "rss+xml"
            /// SOAP; Defined by RFC 3902
            public static let soapXml = "soap+xml"
            /// Web Open Font Format; (candidate recommendation; use application/x-font-woff until standard is official)
            public static let fontWorff = "font-woff"
            /// XHTML; Defined by RFC 3236
            public static let xhtmlXml = "xhtml+xml"
            /// XML files; Defined by RFC 3023
            public static let xml = "xml"
            /// DTD files; Defined by RFC 3023
            public static let xmlDtd = "xml-dtd"
            /// XOP
            public static let xopXml = "xop+xml"
            /// ZIP archive files; Registered[8]
            public static let zip = "zip"
            /// Gzip, Defined in RFC 6713
            public static let gzip = "gzip"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
            /// for Native Client modules the type must be “application/x-nacl”
            public static let xNacl = "x-nacl"
            /// OpenDocument Text; Registered[13]
            public static let vndOpendocText = "vnd.oasis.opendocument.text"
            /// OpenDocument Spreadsheet; Registered[14]
            public static let vndOpendocSpreadsheet = "vnd.oasis.opendocument.spreadsheet"
            /// OpenDocument Presentation; Registered[15]
            public static let vndOpendocPresentation = "vnd.oasis.opendocument.presentation"
            /// OpenDocument Graphics; Registered[16]
            public static let vndOpendocGraphics = "vnd.oasis.opendocument.graphics"
            /// Microsoft Excel files
            public static let vndMsExcel = "vnd.ms-excel"
            /// Microsoft Excel 2007 files
            public static let vndOpenxmlSpreadsheet = "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            /// Microsoft Powerpoint files
            public static let vndMsPowerpoint = "vnd.ms-powerpoint"
            /// Microsoft Powerpoint 2007 files
            public static let vndOpenxmlPresentation = "vnd.openxmlformats-officedocument.presentationml.presentation"
            /// Microsoft Word 2007 files
            public static let vndOpenxmlWord = "vnd.openxmlformats-officedocument.wordprocessingml.document"
            /// Mozilla XUL files
            public static let vndMozillaXul = "vnd.mozilla.xul+xml"
            /// KML files (e.g. for Google Earth)[17]
            public static let vndGgEarthKml = "vnd.google-earth.kml+xml"
            /// KMZ files (e.g. for Google Earth)[18]
            public static let vndGgEarthKmz = "vnd.google-earth.kmz"
            /// Dart files [19]
            public static let dart = "dart"
            /// For download apk files.
            public static let vndApk = "vnd.android.package-archive"
            /// XPS document[20]
            public static let vndXps = "vnd.ms-xpsdocument"
            /// 7-Zip compression format.
            public static let x7z = "x-7z-compressed"
            /// Google Chrome/Chrome OS extension, app, or theme package [23]
            public static let xChromeExt = "x-chrome-extension"
            /// deb (file format), a software package format used by the Debian project
            public static let xDeb = "x-deb"
            /// device-independent document in DVI format
            public static let xDvi = "x-dvi"
            /// TrueType Font No registered MIME type, but this is the most commonly used
            public static let xTtf = "x-font-ttf"
            /// #define MIME_TYPE_APP_X_JAVASCRIPT  @"application/x-javascript"
            public static let xJavascript = "x-javascript"
            /// LaTeX files
            public static let xLatex = "x-latex"
            /// .m3u8 variant playlist
            public static let xM3u8 = "x-mpegURL"
            /// RAR archive files
            public static let xRar = "x-rar-compressed"
            /// Adobe Flash files for example with the extension .swf
            public static let xSwf = "x-shockwave-flash"
            /// StuffIt archive files
            public static let xStuffit = "x-stuffit"
            /// Tarball files
            public static let xTar = "x-tar"
            /// Form Encoded Data; Documented in HTML 4.01 Specification, Section 17.13.4.1
            public static let xWwwForm = "x-www-form-urlencoded"
            /// Add-ons to Mozilla applications (Firefox, Thunderbird, SeaMonkey, and the discontinued Sunbird)
            public static let xXpi = "x-xpinstall"
            /// a variant of PKCS standard files
            public static let txtXPkcs12 = "x-pkcs12"
        }

        public struct TextSubType {

            public static let paramCharset = "charset"

            /// commands; subtype resident in Gecko browsers like Firefox 3.5
            public static let cmd = "cmd"
            /// Cascading Style Sheets; Defined in RFC 2318
            public static let css = "css"
            /// Comma-separated values; Defined in RFC 4180
            public static let csv = "csv"
            /// HTML; Defined in RFC 2854
            public static let html = "html"
            /// JavaScript; Defined in and made obsolete in RFC 4329 in order to discourage its usage in favor of application/javascript. However, text/javascript is allowed in HTML 4 and 5 and, unlike application/javascript, has cross-browser support. The "type" attribute of the <script> tag in HTML5 is optional and there is no need to use it at all since all browsers have always assumed the correct default (even in HTML 4 where it was required by the specification).
            public static let javascript = "javascript (Obsolete)"
            /// Textual data; Defined in RFC 2046 and RFC 3676
            public static let plain = "plain"
            /// RTF; Defined by Paul Lindner
            public static let rtf = "rtf"
            /// vCard (contact information); Defined in RFC 6350
            public static let vcard = "vcard"
            /// Extensible Markup Language; Defined in RFC 3023
            public static let xml = "xml"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
            /// ABC music notation; Registered[11]
            public static let abc = "vnd.abc"
            /// GoogleWebToolkit data
            public static let txtXGwtRpc = "x-gwt-rpc"
            /// jQuery template data
            public static let txtXJqueryTmpl = "x-jquery-tmpl"
            /// Markdown formatted text
            public static let txtXMarkdown = "x-markdown"
        }

        public struct ImageSubType {
            /// GIF image; Defined in RFC 2045 and RFC 2046
            public static let gif = "gif"
            /// JPEG JFIF image; Defined in RFC 2045 and RFC 2046
            public static let jpeg = "jpeg"
            /// JPEG JFIF image; Associated with Internet Explorer; Listed in ms775147(v=vs.85) - Progressive JPEG, initiated before global browser support for progressive JPEGs (Microsoft and Firefox).
            public static let pjpeg = "pjpeg"
            /// Portable Network Graphics; Registered,[10] Defined in RFC 2083
            public static let png = "png"
            /// SVG vector image; Defined in SVG Tiny 1.2 Specification Appendix M
            public static let svg = "svg+xml"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
            /// GIMP image file
            public static let xcf = "x-xcf"
        }

        public struct AudioSubType {
            /// μ-law audio at 8 kHz, 1 channel; Defined in RFC 2046
            public static let basic = "basic"
            /// 24bit Linear PCM audio at 8–48 kHz, 1-N channels; Defined in RFC 3190
            public static let l24 = "L24"
            /// MP4 audio
            public static let mp4 = "mp4"
            /// MP3 or other MPEG audio; Defined in RFC 3003
            public static let mpeg = "mpeg"
            /// Ogg Vorbis, Speex, Flac and other audio; Defined in RFC 5334
            public static let ogg = "ogg"
            /// Opus audio
            public static let opus = "opus"
            /// Vorbis encoded audio; Defined in RFC 5215
            public static let vorbis = "vorbis"
            /// RealAudio; Documented in RealPlayer Help[9]
            public static let real = "vnd.rn-realaudio"
            /// WAV audio; Defined in RFC 2361
            public static let wave = "vnd.wave"
            /// WebM open media format
            public static let webm = "webm"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
            /// .aac audio files
            public static let xAac = "x-aac"
            /// Apple's CAF audio files
            public static let xCaf = "x-caf"
        }

        public struct VideoSubType {
            public static let mpeg = "mpeg"
            /// MP4 video; Defined in RFC 4337
            public static let mp4 = "mp4"
            /// Ogg Theora or other video (with audio); Defined in RFC 5334
            public static let ogg = "ogg"
            /// QuickTime video; Registered[12]
            public static let quicktime = "quicktime"
            /// WebM Matroska-based open media format
            public static let webm = "webm"
            /// Matroska open media format
            public static let mkv = "x-matroska"
            /// Windows Media Video; Documented in Microsoft KB 288102
            public static let wmv = "x-ms-wmv"
            /// Flash video (FLV files)
            public static let flv = "x-flv"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
        }

        public struct MessageSubType {
            /// Defined in RFC 2616
            public static let http = "http"
            /// IMDN Instant Message Disposition Notification; Defined in RFC 5438
            public static let imdn = "imdn+xml"
            /// Email; Defined in RFC 2045 and RFC 2046
            public static let partial = "partial"
            /// Email; EML files, MIME files, MHT files, MHTML files; Defined in RFC 2045 and RFC 2046
            public static let rfc822 = "rfc822"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
        }

        public struct MultipartSubType {

            public static let paramBoundary = "boundary"

            /// MIME Email; Defined in RFC 2045 and RFC 2046
            public static let mixed = "mixed"
            /// MIME Email; Defined in RFC 2045 and RFC 2046
            public static let alternative = "alternative"
            /// MIME Email; Defined in RFC 2387 and used by MHTML (HTML mail)
            public static let related = "related"
            /// MIME Webform; Defined in RFC 2388
            public static let formData = "form-data"
            /// Defined in RFC 1847
            public static let signed = "signed"
            /// Defined in RFC 1847
            public static let encrypted = "encrypted"
            /// example in documentation, Defined in RFC 4735
            public static let example = "example"
        }

    }

    public static let applicationOctetStream = try! NWContentType(type: MainType.application, subType: MainType.ApplicationSubType.octetStream, parameter: nil)
    public static let textPlainUtf8 = try! NWContentType(text: MainType.TextSubType.plain, charset: .utf8)

    /// `type` and `subType` are not validated (be careful).
    public init(type: MainType, subType: String, parameter:(String, String)?) throws {
        var cmt: String? = nil
        if let (paramKey, paramVal) = parameter {
             // parameter key must be ASCII and not contain special chars, non printable chars, space.
            if paramKey.count > 0, let keyData = paramKey.data(using: .ascii) {
                for byte in keyData where NWMimeEspecialsCharacters.contains(Unicode.Scalar(byte)) || byte < 33 || byte > 126 {
                    throw ContentTypeError.invalidParameterName
                }
            } else {
                throw ContentTypeError.invalidParameterName
            }
            // parameter value must be quoted if it contains special chars (I includes space) and must be printable characters (ASCII. to support on-ASCII, we have to implement ABNF encoding).
            var shouldQuote = false
            do {
                shouldQuote = try NWHeaderLine.shouldQuoted(paramVal)
            } catch {
                throw ContentTypeError.invalidParameterValue
            }
            if shouldQuote {
                var targetVal = paramVal
                if paramVal.contains("\"") {
                    targetVal = paramVal.replacingOccurrences(of: "\"", with: "\\\"")
                }
                cmt = paramKey + "=\"\(targetVal)\""
            } else {
                cmt = paramKey + "=" + paramVal
            }
        }
        super.init(key: HTTPRequestHeaderField.contentType.value, value: type.value + "/" + subType, comment: cmt)
    }

    public convenience init(text subType: String, charset: String.Encoding?) throws {
        var params: (String, String)?
        if let chs = charset {
            params = (MainType.TextSubType.paramCharset, chs.httpContentTypeCharset)
        }
        try self.init(type: .text, subType: subType, parameter: params)
    }

    public convenience init(multipart subType: String, boundary: String) throws {
        try self.init(type: .multipart, subType: subType, parameter: (MainType.MultipartSubType.paramBoundary, boundary))
    }

    public convenience init(httpContentType: String) throws {
        let input = httpContentType.lowercased().trimmingCharacters(in: CharacterSet.whitespaces)
        var body: String
        var comment: String
        if let range = input.range(of: ";") {
            body = String(input[..<range.lowerBound]).trimmingCharacters(in: CharacterSet.whitespaces)
            comment = String(input[range.upperBound...]).trimmingCharacters(in: CharacterSet.whitespaces)
        } else {
            body = input
            comment = ""
        }
        var main: String
        var sub: String
        if let range = body.range(of: "/") {
            main = String(body[..<range.lowerBound])
            sub = String(body[range.upperBound...])
        } else {
            main = body
            sub = ""
        }
        var param: (String, String)? = nil
        if comment.count > 0, let range = comment.range(of: "=") {
            let paramK = String(comment[..<range.lowerBound])
            let paramV = String(comment[range.upperBound...])
            param = (paramK, paramV)
        }
        try self.init(type: .init(main), subType: sub, parameter: param)
    }

}

