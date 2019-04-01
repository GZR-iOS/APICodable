//
//  ProgressViewController.swift
//  APICodableExample
//
//  Created by DươngPQ on 11/02/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Cocoa
import APICodable
import CommonLog

#if swift(>=4.2)
extension NSViewController {
    var presenting: NSViewController? {
        return presentingViewController
    }
}
#endif

class ProgressViewController: NSViewController {

    enum JobType {
        case upload
        case download
        case multipart
        case multipartFile
    }

    @IBOutlet private weak var cancelButton: NSButton!
    @IBOutlet private weak var progressBar: NSProgressIndicator!
    @IBOutlet private weak var label: NSTextField!

    var job: JobType? {
        didSet {
            if let task = job {
                switch task {
                case .upload:
                    title = "Upload"
                case .download:
                    title = "Download"
                case .multipart:
                    title = "Multipart Form Data"
                case .multipartFile:
                    title = "Multipart Form Data with Temp File"
                }
            }
        }
    }
    weak var request: NWApiRequest?
    private var caption = ""
    private var resumableData: Data? = nil

    deinit {
        if let req = request {
            req.cancel()
            request = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.isHidden = true
        label.isHidden = true
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let work = job {
            progressBar.isHidden = false
            label.isHidden = false
            switch work {
            case .upload:
                doUpload()
            case .download:
                doDownload()
            case .multipart:
                doMultipart(false)
            case .multipartFile:
                doMultipart(true)
            }
        }
        job = nil
    }

    @IBAction private func cancelButton_onAction(_ sender: NSButton) {
        if let req = request {
            req.cancel()
            cancelButton.title = "Resume"
            cancelButton.isEnabled = false
        } else {
            doDownload()
        }
    }

    private func setProgress(_ ratio: Double) {
        progressBar.doubleValue = ratio * 100.0
        if ratio == 1 {
            label.stringValue = "Done!"
        } else {
            label.stringValue = caption + "\n" + "\(Int(ratio * 100))%"
        }
    }

    private func doUpload() {
        if let url = URL(string: kSampleApiUrl), let fileUrl = Bundle.main.url(forResource: "movie", withExtension: "mp4") {
            CMLog("File to upload:", fileUrl)
            let fSize: UInt64?
            if let filesize = try? (FileManager.default.attributesOfItem(atPath: fileUrl.path) as NSDictionary).fileSize() {
                fSize = filesize
                caption = "Uploading \"\(fileUrl.lastPathComponent)\"\n(\(filesize) bytes)"
            } else {
                fSize = nil
                caption = "Uploading \"\(fileUrl.lastPathComponent)\""
            }
            setProgress(0)
            weak var wSelf = self
            let maker = NWApiBasicUploadRequestMaker()
            maker.contentType = try? NWContentType(type: .video, subType: NWContentType.MainType.VideoSubType.mp4, parameter: nil)
            let handler = NWApiBasicResponseHandler()
            var dataArgs = NWApiRequest.UploadRequestArgument(request: maker, response: handler)
            dataArgs.parameter = fileUrl
            dataArgs.successAction = {(sender, response) in
                if let res = response as? NWApiBasicResponseHandler, let data = res.rawData, let header = res.header {
                    var encoding = String.Encoding.utf8
                    if let contentTypeRaw = header.headerValue(HTTPResponseHeaderField.contentType) as? String, let contentType = try? NWContentType(httpContentType: contentTypeRaw),
                        let params = contentType.getValueAndParameters().1, let encodingName = params[NWContentType.MainType.TextSubType.paramCharset] {
                        encoding = String.Encoding(httpCharset: encodingName)
                    }
                    if let dataStr = String(data: data, encoding: encoding) {
                        CMLog(">>> Request success:", dataStr)
                    } else {
                        CMLog(">>> Request success:", data.count)
                    }
                }
                wSelf?.setProgress(1)
            }
            dataArgs.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.setProgress(1)
            }
            let req = NWApiRequest(link: url, rqType: NWApiRequest.RequestType.upload(dataArgs))
            req.sendingProgressAction = {(send, totalSend, totalExpected, speed, avgSpeed) in
                guard let mSelf = wSelf else { return }
                var progress: Double = 0
                let fileSize = fSize ?? UInt64(totalExpected)
                let txt = "Uploading \"\(fileUrl.lastPathComponent)\"\n(\(fileSize) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if fileSize > 0 {
                    progress = Double(totalSend) / Double(fileSize)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
                setProgress(1)
            }
        }
    }

    private func doDownload() {
        cancelButton.isHidden = false
        cancelButton.title = "Cancel"
        caption = "Downloading \"\(kSampleFileName)\""
        setProgress(0)
        weak var wSelf = self
        var rrequest: NWApiRequest?
        let successAction: NWApiRequest.DownloadSuccessAction = {(sender, response) in
            CMLog(">>> Request success:", (response as? NWApiBasicDownloadResponseHandler)?.destination.path)
            wSelf?.setProgress(1)
            wSelf?.cancelButton.title = "Restart"
        }
        let failureAction: NWApiRequest.DownloadFailureAction = {(sender, response, error) in
            CMLog(">>> Request failed:", error)
            wSelf?.setProgress(1)
            wSelf?.cancelButton.title = "Restart"
        }
        let cancelAction: NWApiRequest.DownloadCancelAction = {(data) in
            wSelf?.resumableData = data
            DispatchQueue.main.async {
                wSelf?.cancelButton.isEnabled = true
            }
        }
        if let dest = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(kSampleFileName) {
            let handler = NWApiBasicDownloadResponseHandler(dest)
            if let data = resumableData {
                var args = NWApiRequest.ResumeRequestArgument(data: data, response: handler)
                args.successAction = successAction
                args.failureAction = failureAction
                args.cancelAction = cancelAction
                rrequest = NWApiRequest(resume: args)
                resumableData = nil
            } else {
                if let url = URL(string: kSampleDlFileUrl) {
                    let maker = NWApiFormUrlEncodedRequestMaker(.urlQuery)
                    var dataArgs = NWApiRequest.DownloadRequestArgument(request: maker, response: handler)
                    dataArgs.successAction = successAction
                    dataArgs.failureAction = failureAction
                    dataArgs.cancelAction = cancelAction
                    rrequest = NWApiRequest(link: url, rqType: .download(dataArgs))
                }
            }
        }

        if let req = rrequest {
            req.downloadProgressAction = {(received, totalReceived, totalExpected, speed, avgSpeed) in
                guard let mSelf = wSelf else { return }
                var progress: Double = 0
                let txt = "Downloading \"\(kSampleFileName)\"\n(\(totalExpected) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if totalExpected > 0 {
                    progress = Double(totalReceived) / Double(totalExpected)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
                cancelButton.isHidden = true
            }
        }
    }

    private func doMultipart(_ useTempFile: Bool) {
        if let url = URL(string: kSampleApiUrl) {
            caption = "Uploading Multipart/Form-Data" + (useTempFile ? " from Temp File" : "")
            setProgress(0)
            weak var wSelf = self
            let handler = NWApiBasicResponseHandler()
            let maker = NWApiMultipartFormDataUploadRequestMaker()
            maker.useTempFile = useTempFile
            var args = NWApiRequest.UploadRequestArgument(request: maker, response: handler)
            var param = Sample()
            param.number = 1
            param.test = "This is test!"
            if useTempFile {
                param.movie = Bundle.main.url(forResource: "movie", withExtension: "mp4")
            } else if let controller = presenting as? ViewController {
                param.image = controller.makeScreenshot()
            }
            args.parameter = param
            args.successAction = {(sender, response) in
                if let res = response as? NWApiBasicResponseHandler, let data = res.rawData {
                    if let dataStr = String(data: data, encoding: .utf8) {
                        CMLog(">>> Request success:", dataStr)
                    } else {
                        CMLog(">>> Request success:", data.count)
                    }
                }
                wSelf?.setProgress(1)
            }
            args.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.setProgress(1)
            }
            let req = NWApiRequest(link: url, rqType: .upload(args))
            req.sendingProgressAction = {(send, totalSend, totalExpected, speed, avgSpeed) in
                guard let mSelf = wSelf else { return }
                var progress: Double = 0
                let txt = "Uploading Multipart/Form-Data" + (useTempFile ? " from Temp File" : "") + "\n(\(totalExpected) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if totalExpected > 0 {
                    progress = Double(totalSend) / Double(totalExpected)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
                setProgress(1)
            }
        }
    }

}
