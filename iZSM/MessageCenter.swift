//
//  MessageCenter.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/9/16.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import Foundation
import UserNotifications
import SmthConnection

class MessageCenter {
    static let kUpdateMessageCountNotification = Notification.Name("UpdateMessageCountNotification")
    static let shared = MessageCenter()
    
    private let setting = AppSetting.shared
    private let api = SmthAPI.shared
    
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
    
    var allCount: Int {
        return mailCount + replyCount + referCount
    }
    
    func readAllMail() {
        guard mailCount > 0 else { return }
        mailCount = 0
        updateBadge()
        notifyOthers()
    }
    
    func readRefer(mode: SMReference.ReferMode, all: Bool = false) {
        switch mode {
        case .reply:
            guard replyCount > 0 else { return }
        case .refer:
            guard referCount > 0 else { return }
        }
        if all {
            switch mode {
            case .reply:
                replyCount = 0
            case .refer:
                referCount = 0
            }
        } else {
            switch mode {
            case .reply:
                replyCount -= 1
            case .refer:
                referCount -= 1
            }
        }
        updateBadge()
        notifyOthers()
    }
    
    private init() {
        mailCount = setting.mailCount
        replyCount = setting.replyCount
        referCount = setting.referCount
    }
    
    private func updateBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = self.allCount
            if let delegate = UIApplication.shared.delegate as? AppDelegate,
                let vc = delegate.tabBarViewController.viewControllers?[3] {
                if self.allCount > 0 {
                    vc.tabBarItem.badgeValue = "\(self.allCount)"
                } else {
                    vc.tabBarItem.badgeValue = nil
                }
            }
        }
    }
    
    private func notifyOthers() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: MessageCenter.kUpdateMessageCountNotification, object: nil)
        }
    }
    
    func checkUnreadMessage() {
        checkUnreadMessage(postUserNotification: false, completionHandler: nil)
    }
    
    func checkUnreadMessage(postUserNotification post: Bool, completionHandler: ((Bool) -> Void)?) {
        if self.setting.accessToken != nil {
            DispatchQueue.global().async {
                let newMailCount = (try? self.api.getMailCount().newCount) ?? 0
                let newReplyCount = (try? self.api.getReferCount(mode: .reply).newCount) ?? 0
                let newReferCount = (try? self.api.getReferCount(mode: .refer).newCount) ?? 0
                
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
                            dPrint("Unable to post new mail notification")
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
                            dPrint("Unable to post new reply notification")
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
                            dPrint("Unable to post new refer notification")
                        }
                    }
                }
                
                self.mailCount = newMailCount
                self.replyCount = newReplyCount
                self.referCount = newReferCount
                
                self.updateBadge()
                self.notifyOthers()
                
                completionHandler?(true)
            }
        } else {
            completionHandler?(false)
            dPrint("no data, user not login or token expired")
        }
    }
}
