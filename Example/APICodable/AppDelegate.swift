//
//  AppDelegate.swift
//
//  Created by soleilpqd@gmail.com on 01/28/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit
import UserNotifications
import APICodable
import CommonLog

let kDomain = "http://127.0.0.1/test/"
let kSampleApiUrl = kDomain + "simple.php"
let kSampleFileName = "movie.mp4"
let kSampleImgFileUrl = kDomain + "Files/image.jpg"
let kSampleDlFileUrl = kDomain + "Files/movie.mp4"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?

    let kBackgroundSessionKey = "BackgroundSession"

    private var userNotificationCompletion: (() -> Void)?
    private var bkgRequestCompletion: (() -> Void)?

    static var app: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    static let notificationCenter = UNUserNotificationCenter.current()

#if swift(>=4.2)
    typealias UIApplicationLaunchOptionsKey = UIApplication.LaunchOptionsKey
#endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.notificationCenter.delegate = self
        let config = URLSessionConfiguration.background(withIdentifier: kBackgroundSessionKey)
        config.isDiscretionary = true
        NWApiManager.shared.setSession(configuration: config, for: kBackgroundSessionKey)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert])
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        bkgRequestCompletion = completionHandler
    }

    private func cleanupBkgDownload() {
        if let action = bkgRequestCompletion {
            action()
        }
        if let action = userNotificationCompletion {
            action()
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        userNotificationCompletion = completionHandler
        var rrequest: NWApiRequest?
        let successAction: NWApiRequest.DownloadSuccessAction = {(sender, response) in
            LocalNotificationManager.shared.scheduleDownloadFinishNotification(true)
            AppDelegate.app.cleanupBkgDownload()
        }
        let failureAction: NWApiRequest.DownloadFailureAction = {(sender, response, error) in
            LocalNotificationManager.shared.scheduleDownloadFinishNotification(false)
            AppDelegate.app.cleanupBkgDownload()
        }
        if let dest = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(kSampleFileName) {
            let handler = NWApiBasicDownloadResponseHandler(dest)
            if let url = URL(string: kSampleDlFileUrl) {
                let maker = NWApiFormUrlEncodedRequestMaker(.urlQuery)
                var dataArgs = NWApiRequest.DownloadRequestArgument(request: maker, response: handler)
                dataArgs.successAction = successAction
                dataArgs.failureAction = failureAction
                rrequest = NWApiRequest(link: url, rqType: .download(dataArgs))
            }
        }

        if let req = rrequest {
            do {
                try req.start(kBackgroundSessionKey)
            } catch (let error) {
                CMLog(">>> ERROR Start request:", error)
            }
        }
    }

}

