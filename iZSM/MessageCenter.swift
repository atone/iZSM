//
//  MessageCenter.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/16.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import Foundation
import UserNotifications

class MessageCenter {
    static let kUpdateMessageCountNotification = Notification.Name("UpdateMessageCountNotification")
    static let shared = MessageCenter()
    
    private let setting = AppSetting.shared
    private let api = SmthAPI()
    
    var mailCount: Int {
        didSet {
            setting.mailCount = mailCount
        }
    }
    var replyCount: Int {
        didSet {
            setting.replyCount = replyCount
        }
    }
    var referCount: Int {
        didSet {
            setting.referCount = referCount
        }
    }
    
    private init() {
        mailCount = setting.mailCount
        replyCount = setting.replyCount
        referCount = setting.referCount
    }
    
    func checkUnreadMessage() {
        checkUnreadMessage(postUserNotification: false, completionHandler: nil)
    }
    
    func checkUnreadMessage(postUserNotification post: Bool, completionHandler: ((Bool) -> Void)?) {
        if self.setting.accessToken != nil {
            DispatchQueue.global().async {
                let newMailCount = self.api.getMailStatus()?.newCount ?? 0
                let newReplyCount = self.api.getReferCount(mode: .ReplyToMe)?.newCount ?? 0
                let newReferCount = self.api.getReferCount(mode: .AtMe)?.newCount ?? 0
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = newMailCount + newReplyCount + newReferCount
                }
                dPrint("mail \(self.mailCount) -> \(newMailCount), reply \(self.replyCount) -> \(newReplyCount), refer \(self.referCount) -> \(newReferCount)")
                
                if post && newMailCount > self.mailCount {
                    dPrint("post new mail notification")
                    let content = UNMutableNotificationContent()
                    content.title = "新邮件"
                    content.body = "您收到 \(newMailCount) 封新邮件"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "zsmth.newmail", content: content, trigger: trigger)
                    let center = UNUserNotificationCenter.current()
                    center.add(request) { error in
                        if error != nil {
                            print("Unable to post new mail notification")
                        }
                    }
                }
                
                if post && newReplyCount > self.replyCount {
                    dPrint("post new reply notification")
                    let content = UNMutableNotificationContent()
                    content.title = "新回复"
                    content.body = "您收到 \(newReplyCount) 条新回复"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "zsmth.newreply", content: content, trigger: trigger)
                    let center = UNUserNotificationCenter.current()
                    center.add(request) { error in
                        if error != nil {
                            print("Unable to post new reply notification")
                        }
                    }
                }
                
                if post && newReferCount > self.referCount {
                    dPrint("post new refer notification")
                    let content = UNMutableNotificationContent()
                    content.title = "新提醒"
                    content.body = "有人 @ 了您"
                    content.sound = UNNotificationSound.default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: "zsmth.newrefer", content: content, trigger: trigger)
                    let center = UNUserNotificationCenter.current()
                    center.add(request) { error in
                        if error != nil {
                            print("Unable to post new refer notification")
                        }
                    }
                }
                
                self.mailCount = newMailCount
                self.replyCount = newReplyCount
                self.referCount = newReferCount
                
                NotificationCenter.default.post(name: MessageCenter.kUpdateMessageCountNotification, object: nil)
                completionHandler?(true)
            }
        } else {
            completionHandler?(false)
            dPrint("no data, user not login or token expired")
        }
    }
}
