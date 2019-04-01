//
//  ViewController.swift
//
//  Created by soleilpqd@gmail.com on 01/28/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit
import APICodable
import CommonLog

extension UIView {

    func capture() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, UIScreen.main.scale)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

}

struct Sample: Encodable {
    var number: Int?
    var test: String?
    var image: UIImage?
    var movie: URL?
}

struct EXSampleResponse: Codable {

    var paramsCount: Int?
    var method: String?
    var files: String?
    var filesCount: Int?
    var header: [String: String]?
    var params: String?

    enum CodingKeys: String, CodingKey {
        case paramsCount = "params_count"
        case method
        case files
        case filesCount = "files_count"
        case header
        case params
    }

}


class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var indicatorContainerView: UIView!
    @IBOutlet private weak var indicatorView: UIActivityIndicatorView!
    private var list = [(String, () -> Void)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        list.append(("GET", testDataApiGet))
        list.append(("POST", testDataApiPost))
        list.append(("POST Raw Text", testRawRequest))
        list.append(("POST Raw Image", testRawImageRequest))
        list.append(("Upload Text", testUploadRequest))
        list.append(("Upload Image", testUploadImageRequest))
        list.append(("Upload File", testUploadFileRequest))
        list.append(("Upload File with progress", testUploadProgressFile))
        list.append(("Download", testDownload))
        list.append(("Download with propress", testDownloadWithProgress))
        list.append(("Multipart/Form-Data", testMultiPart))
        list.append(("Multipart/Form-Data Upload", testMultiPartUpload))
        list.append(("Multipart/Form-Data Upload File", testMultiPartUploadFile))
        list.append(("JSON Response", testResponseJson))
        list.append(("Background download", testBackground))
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProgressSegue", let job = sender as? ProgressViewController.JobType,
            let destination = segue.destination as? ProgressViewController {
            destination.job = job
        }
        hideIndicator()
    }

    private func showIndicator() {
        indicatorContainerView.isHidden = false
        indicatorView.startAnimating()
    }

    private func hideIndicator() {
        indicatorView.stopAnimating()
        indicatorContainerView.isHidden = true
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func makeDataRequest(maker: NWApiRequestDataMaker, parameter: Any?) {
        if let url = URL(string: kSampleApiUrl) {
            weak var wSelf = self
            let handler = NWApiBasicResponseHandler()
            var dataArgs = NWApiRequest.DataRequestArgument(request: maker, response: handler)
            dataArgs.parameter = parameter
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
                wSelf?.hideIndicator()
            }
            dataArgs.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.hideIndicator()
            }
            do {
                let req = NWApiRequest(link: url, rqType: NWApiRequest.RequestType.data(dataArgs))
                try req.start()
                showIndicator()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

    private func makeUploadRequest(maker: NWApiRequestUploadMaker, parameter: Any?) {
        if let url = URL(string: kSampleApiUrl) {
            weak var wSelf = self
            let handler = NWApiBasicResponseHandler()
            var dataArgs = NWApiRequest.UploadRequestArgument(request: maker, response: handler)
            dataArgs.parameter = parameter
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
                wSelf?.hideIndicator()
            }
            dataArgs.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.hideIndicator()
            }
            do {
                let req = NWApiRequest(link: url, rqType: NWApiRequest.RequestType.upload(dataArgs))
                try req.start()
                showIndicator()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

    private func testFormDataUrlEncoded(_ type: NWApiFormUrlEncodedRequestMaker.RequestType) {
        let maker = NWApiFormUrlEncodedRequestMaker(type)
        makeDataRequest(maker: maker, parameter: ["test": 1, "test2": 2])
    }

    private func testDataApiGet() {
        testFormDataUrlEncoded(.urlQuery)
    }

    private func testDataApiPost() {
        testFormDataUrlEncoded(.requestBody)
    }

    private func testRawRequest() {
        let maker = NWApiBasicBodyRequestMaker()
        makeDataRequest(maker: maker, parameter: "This is test!")
    }

    private func testRawImageRequest() {
        let maker = NWApiBasicBodyRequestMaker()
        makeDataRequest(maker: maker, parameter: self.view.window?.capture())
    }

    private func testUploadRequest() {
        let maker = NWApiBasicUploadRequestMaker()
        makeUploadRequest(maker: maker, parameter: "This is test!")
    }

    private func testUploadImageRequest() {
        let maker = NWApiBasicUploadRequestMaker()
        makeUploadRequest(maker: maker, parameter: self.view.window?.capture()!)
    }

    private func testUploadFileRequest() {
        // make file
        if let image = self.view.window?.capture(), let data = image.jpegData(),
            var url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            url.appendPathComponent("capture.jpg")
            CMLog("File to upload:", url)
            do {
                try data.write(to: url)
                let maker = NWApiBasicUploadRequestMaker()
                maker.contentType = try? NWContentType(type: .image, subType: NWContentType.MainType.ImageSubType.jpeg, parameter: nil)
                makeUploadRequest(maker: maker, parameter: url)
            } catch (let err) {
                CMLog(">>> ERROR Start request:", err)
            }
        }
    }

    private func testUploadProgressFile() {
        performSegue(withIdentifier: "ProgressSegue", sender: ProgressViewController.JobType.upload)
    }

    private func testDownload() {
        if let url = URL(string: kSampleImgFileUrl),
            let dest = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("image.jpg") {
            weak var wSelf = self
            let maker = NWApiFormUrlEncodedRequestMaker(.urlQuery)
            let handler = NWApiBasicDownloadResponseHandler(dest)
            var dataArgs = NWApiRequest.DownloadRequestArgument(request: maker, response: handler)
            dataArgs.successAction = {(sender, response) in
                CMLog(">>> Request success:", (response as? NWApiBasicDownloadResponseHandler)?.destination.path)
                wSelf?.hideIndicator()
            }
            dataArgs.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.hideIndicator()
            }
            let req = NWApiRequest(link: url, rqType: .download(dataArgs))
            do {
                try req.start()
                showIndicator()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

    private func testDownloadWithProgress() {
        performSegue(withIdentifier: "ProgressSegue", sender: ProgressViewController.JobType.download)
    }

    private func testMultiPart() {
        if let url = URL(string: kSampleApiUrl) {
            weak var wSelf = self
            let handler = NWApiBasicResponseHandler()
            let maker = NWApiMultipartFormDataRequestMaker()
            var args = NWApiRequest.DataRequestArgument(request: maker, response: handler)
            var param = Sample()
            param.number = 1
            param.test = "This is test!"
            param.image = self.view.window?.capture()
            args.parameter = param
            args.successAction = {(sender, response) in
                if let res = response as? NWApiBasicResponseHandler, let data = res.rawData {
                    if let dataStr = String(data: data, encoding: .utf8) {
                        CMLog(">>> Request success:", dataStr)
                    } else {
                        CMLog(">>> Request success:", data.count)
                    }
                }
                wSelf?.hideIndicator()
            }
            args.failureAction = {(sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.hideIndicator()
            }
            let req = NWApiRequest(link: url, rqType: .data(args))
            do {
                try req.start()
                showIndicator()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

    private func testMultiPartUpload() {
        performSegue(withIdentifier: "ProgressSegue", sender: ProgressViewController.JobType.multipart)
    }

    private func testMultiPartUploadFile() {
        performSegue(withIdentifier: "ProgressSegue", sender: ProgressViewController.JobType.multipartFile)
    }

    private func testResponseJson() {
        if let url = URL(string: kSampleApiUrl) {
            weak var wSelf = self
            let req = NWApiRequest(get: url, parameter: ["test": 1, "test2": 2], onSuccess: { (sender, response) in
                if let res = response as? NWApiJsonResponseHandler<EXSampleResponse> {
                    CMLog(">>> Request success:", res.responseObject)
                }
                wSelf?.hideIndicator()
            }, onFailure: { (sender, response, error) in
                CMLog(">>> Request failed:", error)
                wSelf?.hideIndicator()
            }, jsonResponseModel: EXSampleResponse.self)
            req.requestConfigurationAction = {(request) in
                request.setValue("TEST", forHTTPHeaderField: "head")
            }
            do {
                try req.start()
                showIndicator()
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

    private func testBackground() {
        performSegue(withIdentifier: "BkgInstructionSegue", sender: nil)
    }

    // MARK: - Table view

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = list[indexPath.row]
        cell.textLabel?.text = item.0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = list[indexPath.row]
        showIndicator()
        item.1()
    }

}

