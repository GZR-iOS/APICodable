//
//  ProgressViewController.swift
//  APICodable_Example
//
//  Created by DươngPQ on 30/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit
import APICodable

class ProgressViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var progressConstraint: NSLayoutConstraint!
    @IBOutlet private weak var progressView: UIView!
    @IBOutlet private weak var cancelButton: UIButton!

    enum JobType {
        case upload
        case download
        case multipart
        case multipartFile
    }

    var job: JobType?
    weak var request: NWApiRequest?
    private var caption = ""
    private var resumableData: Data? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.superview?.isHidden = true
        titleLabel.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let work = job {
            progressView.superview?.isHidden = false
            titleLabel.isHidden = false
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let req = request {
            req.cancel()
            request = nil
        }
    }

    @IBAction private func cancelButton_onAction(_ sender: UIButton) {
        if let req = request {
            req.cancel()
            cancelButton.setTitle("Resume", for: .normal)
            cancelButton.isEnabled = false
        } else {
            doDownload()
        }
    }

    private func setProgress(_ ratio: CGFloat) {
        let target = progressView.superview!
        target.removeConstraint(progressConstraint)
        let constraint = NSLayoutConstraint(item: progressView, attribute: .width, relatedBy: .equal,
                                            toItem: target, attribute: .width,
                                            multiplier: ratio, constant: 0)
        target.addConstraint(constraint)
        progressConstraint = constraint
        target.setNeedsLayout()
        if ratio == 1 {
            titleLabel.text = "Done!"
        } else {
            titleLabel.text = caption + "\n" + "\(Int(ratio * 100))%"
        }
    }

    private func doUpload() {
        if let url = URL(string: kSampleApiUrl), let fileUrl = Bundle.main.url(forResource: "movie", withExtension: "mp4") {
            NWLog("File to upload:", fileUrl)
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
                if let res = response as? NWApiBasicResponseHandler, let data = res.body, let header = res.response {
                    var encoding = String.Encoding.utf8
                    if let contentTypeRaw = header.headerValue(HTTPResponseHeaderField.contentType) as? String, let contentType = try? NWContentType(httpContentType: contentTypeRaw),
                        let params = contentType.getValueAndParameters().1, let encodingName = params[NWContentType.MainType.TextSubType.paramCharset] {
                        encoding = String.Encoding(httpCharset: encodingName)
                    }
                    if let dataStr = String(data: data, encoding: encoding) {
                        NWLog(">>> Request success:", dataStr)
                    } else {
                        NWLog(">>> Request success:", data.count)
                    }
                }
                wSelf?.setProgress(1)
            }
            dataArgs.failureAction = {(sender, response, error) in
                NWLog(">>> Request failed:", error)
                wSelf?.setProgress(1)
            }
            let req = NWApiRequest(link: url, rqType: NWApiRequest.RequestType.upload(dataArgs))
            req.sendingProgressAction = {(send, totalSend, totalExpected, speed, avgSpeed) in
                guard let mSelf = wSelf else { return }
                var progress: CGFloat = 0
                let fileSize = fSize ?? UInt64(totalExpected)
                let txt = "Uploading \"\(fileUrl.lastPathComponent)\"\n(\(fileSize) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if fileSize > 0 {
                    progress = CGFloat(totalSend) / CGFloat(fileSize)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                NWLog(">>> ERROR Start request:", error)
                setProgress(1)
            }
        }
    }

    private func doDownload() {
        cancelButton.isHidden = false
        cancelButton.setTitle("Cancel", for: .normal)
        caption = "Downloading \"\(kSampleFileName)\""
        setProgress(0)
        weak var wSelf = self
        var rrequest: NWApiRequest?
        let successAction: NWApiRequest.DownloadSuccessAction = {(sender, response) in
            NWLog(">>> Request success:", (response as? NWApiBasicDownloadResponseHandler)?.destination.path)
            wSelf?.setProgress(1)
            wSelf?.cancelButton.setTitle("Restart", for: .normal)
        }
        let failureAction: NWApiRequest.DownloadFailureAction = {(sender, response, error) in
            NWLog(">>> Request failed:", error)
            wSelf?.setProgress(1)
            wSelf?.cancelButton.setTitle("Restart", for: .normal)
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
                var progress: CGFloat = 0
                let txt = "Downloading \"\(kSampleFileName)\"\n(\(totalExpected) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if totalExpected > 0 {
                    progress = CGFloat(totalReceived) / CGFloat(totalExpected)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                NWLog(">>> ERROR Start request:", error)
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
            } else {
                param.image = self.view.window?.capture()
            }
            args.parameter = param
            args.successAction = {(sender, response) in
                if let res = response as? NWApiBasicResponseHandler, let data = res.body {
                    if let dataStr = String(data: data, encoding: .utf8) {
                        NWLog(">>> Request success:", dataStr)
                    } else {
                        NWLog(">>> Request success:", data.count)
                    }
                }
                wSelf?.setProgress(1)
            }
            args.failureAction = {(sender, response, error) in
                NWLog(">>> Request failed:", error)
                wSelf?.setProgress(1)
            }
            let req = NWApiRequest(link: url, rqType: .upload(args))
            req.sendingProgressAction = {(send, totalSend, totalExpected, speed, avgSpeed) in
                guard let mSelf = wSelf else { return }
                var progress: CGFloat = 0
                let txt = "Uploading Multipart/Form-Data" + (useTempFile ? " from Temp File" : "") + "\n(\(totalExpected) bytes)\nSpeed: \(Int(speed)) B/s\nAvgSpeed: \(Int(avgSpeed)) B/s"
                if totalExpected > 0 {
                    progress = CGFloat(totalSend) / CGFloat(totalExpected)
                }
                mSelf.caption = txt
                mSelf.setProgress(progress)
            }
            request = req
            do {
                try req.start()
            } catch (let error) {
                NWLog(">>> ERROR Start request:", error)
                setProgress(1)
            }
        }
    }

}
