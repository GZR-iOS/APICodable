//
//  LocalNotificationManager.swift
//  APICodable_Example
//
//  Created by DươngPQ on 11/02/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit
import UserNotifications

class LocalNotificationManager {

    let kFirstRequestID = "Test"

    static let shared = LocalNotificationManager()

    private var isClearPending = false
    private var isClearDeleiver = false

    private func clearNotifications() {
        isClearPending = false
        isClearDeleiver = false
        AppDelegate.notificationCenter.getPendingNotificationRequests { (requests) in
            AppDelegate.notificationCenter.removeAllPendingNotificationRequests()
            self.isClearPending = true
            self.registNotification()
        }
        AppDelegate.notificationCenter.getDeliveredNotifications { (requests) in
            AppDelegate.notificationCenter.removeAllDeliveredNotifications()
            self.isClearDeleiver = true
            self.registNotification()
        }
    }

    private func registNotification() {
        guard isClearPending && isClearDeleiver else { return }
        let action = UNNotificationAction(identifier: "myNotificationCategoryAction", title: "Start download", options: [])
        let category = UNNotificationCategory(identifier: "myNotificationCategory", actions: [action], intentIdentifiers: [], options: [])
        AppDelegate.notificationCenter.setNotificationCategories([category])
        let content = UNMutableNotificationContent()
        content.title = "Test background download"
        content.body = "Pull down this notification & tap 'Start download'! Then wait for 2nd notification about downloading result."
        content.categoryIdentifier = "myNotificationCategory"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
        let request = UNNotificationRequest(identifier: kFirstRequestID, content: content, trigger: trigger)
        AppDelegate.notificationCenter.add(request) { (error) in
            print("Regist " + (error != nil ? error!.localizedDescription : "success"))
        }
    }

    private func askNotificationPermission() {
        AppDelegate.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) {[unowned self] (result, error) in
            print("PERMISSION", result, error)
            if result {
                self.clearNotifications()
            }
        }
    }

    func scheduleDownloadNotification() {
        askNotificationPermission()
    }

    func scheduleDownloadFinishNotification(_ result: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Test background download"
        content.body = "Background downloading finishes: " + (result ? "success" : "failure")
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: kFirstRequestID, content: content, trigger: trigger)
        AppDelegate.notificationCenter.add(request) { (error) in
            print("Regist " + (error != nil ? error!.localizedDescription : "success"))
        }
    }


}
