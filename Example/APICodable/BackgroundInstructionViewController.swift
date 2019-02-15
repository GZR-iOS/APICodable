//
//  BackgroundInstructionViewController.swift
//  APICodable_Example
//
//  Created by DươngPQ on 11/02/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import UIKit

class BackgroundInstructionViewController: UIViewController {

    @IBAction private func startButton_onTap(_ sender: UIButton) {
        LocalNotificationManager.shared.scheduleDownloadNotification()
    }

}
