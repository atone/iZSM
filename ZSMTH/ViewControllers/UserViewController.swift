//
//  UserViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class UserViewController: UITableViewController {

    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {
            if let avatar = avatarImageView {
                avatar.layer.cornerRadius = avatar.frame.width / 2
                avatar.clipsToBounds = true
            }
        }
    }
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!

    @IBOutlet weak var inboxLabel: UILabel!
    @IBOutlet weak var outboxLabel: UILabel!
    @IBOutlet weak var replyLabel: UILabel!
    @IBOutlet weak var referLabel: UILabel!
    @IBOutlet weak var settingLabel: UILabel!

    let api = SmthAPI()
    let setting = AppSetting.sharedSetting()

    private var newMailCount: Int = 0 { didSet { updateUI() } }
    private var newReplyCount: Int = 0 { didSet { updateUI() } }
    private var newAtCount: Int = 0 { didSet { updateUI() } }

    private var lastMailCount = 0
    private var lastReplyCount = 0
    private var lastAtCount = 0

    private var hasNewMail: Bool {
        return (newMailCount != lastMailCount && newMailCount != 0) ? true : false
    }
    
    private var hasNewReply: Bool {
        return (newReplyCount != lastReplyCount && newReplyCount != 0) ? true : false
    }

    private var hasNewAt: Bool {
        return (newAtCount != lastAtCount && newAtCount != 0) ? true : false
    }

    var hasNewMessage: Bool {
        return hasNewMail || hasNewReply || hasNewAt
    }

    private var userInfo: SMUser? {
        didSet {
            if let url = avatarURL(userInfo) {
                avatarImageView.kf_setImageWithURL(url)
            } else {
                avatarImageView.image = nil
            }

            nickNameLabel?.text = userInfo?.nick ?? " "
            userIDLabel?.text = userInfo?.id ?? " "
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // add observer to font size change
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(UserViewController.preferredFontSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
    }

    // remove observer of notification
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: NSNotification) {
        updateUI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedRow, animated: true)
        }

        checkNewMailAndReferenceBackgroundMode(false, completionHandler: nil)

        if userInfo != nil {
            return
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var userInfo: SMUser?
            if let username = self.setting.username {
                userInfo = self.api.getUserInfo(userID: username)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.userInfo = userInfo
            }
        }
    }

    private func avatarURL(user: SMUser?) -> NSURL? {
        let avatarName = user?.faceURL ?? ""
        var urlString: String
        if avatarName.rangeOfString(".") != nil {
            urlString = "http://images.newsmth.net/nForum/uploadFace/\(String(avatarName[avatarName.startIndex]).uppercaseString)/\(avatarName)"
        } else if !avatarName.isEmpty {
            urlString = "http://images.newsmth.net/nForum/uploadFace/\(String(avatarName[avatarName.startIndex]).uppercaseString)/\(avatarName).jpg"
        } else {
            return nil
        }
        return NSURL(string: urlString)
    }

    func attrTextFromString(string: String, withNewFlag flag: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString(string: string)
        if flag {
            result.appendAttributedString(NSAttributedString(string: " [新]", attributes: [NSForegroundColorAttributeName: UIColor.redColor()]))
        }
        result.addAttribute(NSFontAttributeName, value: UIFont.preferredFontForTextStyle(UIFontTextStyleBody), range: NSMakeRange(0, result.length))
        return result
    }

    func checkNewMailAndReferenceBackgroundMode(backgroundMode: Bool, completionHandler: ((Bool) -> Void)?) {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

            let newMailCount = self.api.getMailStatus()?.newCount ?? 0
            let newReplyCount = self.api.getReferCount(mode: .ReplyToMe)?.newCount ?? 0
            let newAtCount = self.api.getReferCount(mode: .AtMe)?.newCount ?? 0

            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                self.lastMailCount = self.newMailCount
                self.newMailCount = newMailCount
                self.lastReplyCount = self.newReplyCount
                self.newReplyCount = newReplyCount
                self.lastAtCount = self.newAtCount
                self.newAtCount = newAtCount
                let allCount = newMailCount + newReplyCount + newAtCount
                UIApplication.sharedApplication().applicationIconBadgeNumber = allCount
                if allCount > 0 {
                    self.navigationController?.tabBarItem.badgeValue = "\(allCount)"
                } else {
                    self.navigationController?.tabBarItem.badgeValue = nil
                }
                
                if backgroundMode {
                    if self.hasNewMail {
                        let mailNotif = UILocalNotification()
                        mailNotif.alertAction = nil
                        mailNotif.alertBody = "您收到 \(self.newMailCount) 封新邮件"
                        mailNotif.category = "新邮件"
                        mailNotif.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().presentLocalNotificationNow(mailNotif)
                    }
                    if self.hasNewReply {
                        let replyNotif = UILocalNotification()
                        replyNotif.alertAction = nil
                        replyNotif.alertBody = "您收到 \(self.newReplyCount) 条新回复"
                        replyNotif.category = "新回复"
                        replyNotif.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().presentLocalNotificationNow(replyNotif)
                    }
                    if self.hasNewAt {
                        let atNotif = UILocalNotification()
                        atNotif.alertAction = nil
                        atNotif.alertBody = "有人 @ 了您"
                        atNotif.category = "新提醒"
                        atNotif.soundName = UILocalNotificationDefaultSoundName
                        UIApplication.sharedApplication().presentLocalNotificationNow(atNotif)
                    }
                }
                completionHandler?(self.hasNewMessage)
            }
        }
    }


    @IBAction func logout(segue: UIStoryboardSegue) {
        networkActivityIndicatorStart()
        let hud = MBProgressHUD.showHUDAddedTo(navigationController?.view, animated: true)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.api.logoutBBS()
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                hud.mode = .Text
                if self.api.errorCode == 0 {
                    hud.labelText = "注销成功"
                } else if self.api.errorDescription != nil && self.api.errorDescription! != "" {
                    hud.labelText = self.api.errorDescription!
                } else {
                    hud.labelText = "出错了"
                }
                hud.hide(true, afterDelay: 1)
                self.setting.username = nil
                self.setting.password = nil
                self.setting.accessToken = nil
                for navvc in self.tabBarController?.viewControllers as! [UINavigationController] {
                    if let basevc = navvc.visibleViewController as? BaseTableViewController {
                        basevc.clearContent()
                    }
                }
                self.userInfo = nil

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                    self.tabBarController?.selectedIndex = 0
                    return
                }

            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath {
        case NSIndexPath(forRow: 0, inSection: 0):
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        case NSIndexPath(forRow: 0, inSection: 1):
            if let mbvc = storyboard?.instantiateViewControllerWithIdentifier("MailBoxViewController") as? MailBoxViewController {
                mbvc.inbox = true
                showViewController(mbvc, sender: self)
            }
        case NSIndexPath(forRow: 1, inSection: 1):
            if let mbvc = storyboard?.instantiateViewControllerWithIdentifier("MailBoxViewController") as? MailBoxViewController {
                mbvc.inbox = false
                showViewController(mbvc, sender: self)
            }
        case NSIndexPath(forRow: 2, inSection: 1):
            if let rvc = storyboard?.instantiateViewControllerWithIdentifier("ReminderViewController") as? ReminderViewController {
                rvc.replyMe = true
                showViewController(rvc, sender: self)
            }
        case NSIndexPath(forRow: 3, inSection: 1):
            if let rvc = storyboard?.instantiateViewControllerWithIdentifier("ReminderViewController") as? ReminderViewController {
                rvc.replyMe = false
                showViewController(rvc, sender: self)
            }
        default:
            break
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == NSIndexPath(forRow: 0, inSection: 0) {
            return 81
        } else {
            return UITableViewAutomaticDimension
        }
    }

    func updateUI() {
        inboxLabel?.attributedText = attrTextFromString("收件箱", withNewFlag: newMailCount > 0)
        outboxLabel?.attributedText = attrTextFromString("发件箱", withNewFlag: false)
        replyLabel?.attributedText = attrTextFromString("回复我", withNewFlag: newReplyCount > 0)
        referLabel?.attributedText = attrTextFromString("提到我", withNewFlag: newAtCount > 0)
        settingLabel?.attributedText = attrTextFromString("设置", withNewFlag: false)
    }

}
