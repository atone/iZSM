//
//  UserViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class UserViewController: UITableViewController {
    
    let api = SmthAPI()
    let setting = AppSetting.sharedSetting()

    //let cellStrings = [[""], ["收件箱", "发件箱", "回复我", "提到我"], ["设置"]]
    let cellStrings = [[""], ["收件箱", "发件箱", "回复我", "提到我"]]

    private var newMailCount: Int = 0 { didSet { tableView?.reloadData() } }
    private var newReplyCount: Int = 0 { didSet { tableView?.reloadData() } }
    private var newAtCount: Int = 0 { didSet { tableView?.reloadData() } }

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
            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? AvatarViewCell
            if let url = avatarURL(userInfo) {
                cell?.avatarImageView.setImageWithURL(url)
            } else {
                cell?.avatarImageView.image = nil
            }

            cell?.nickNameLabel?.text = userInfo?.nick ?? " "
            cell?.userIDLabel?.text = userInfo?.id ?? " "
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // add observer to font size change
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "preferredFontSizeChanged:",
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
    }

    // remove observer of notification
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: NSNotification) {
        tableView?.reloadData()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
        var result = NSMutableAttributedString(string: string)
        if flag {
            result.appendAttributedString(NSAttributedString(string: " [新]", attributes: [NSForegroundColorAttributeName: UIColor.redColor()]))
        }
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


    @IBAction func logout(sender: UIButton) {
        networkActivityIndicatorStart()
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
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

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == NSIndexPath(forRow: 0, inSection: 0) {
            return 81
        } else {
            return UITableViewAutomaticDimension
        }
    }

    // Mark: - Data Source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return cellStrings.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellStrings[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let userCell = tableView.dequeueReusableCellWithIdentifier("Me", forIndexPath: indexPath) as! AvatarViewCell
            // do some customsize
            return userCell
        } else {
            
            var identifier: String
            switch indexPath {
            case NSIndexPath(forRow: 0, inSection: 1), NSIndexPath(forRow: 1, inSection: 1):
                identifier = "Mailbox"
            case NSIndexPath(forRow: 2, inSection: 1), NSIndexPath(forRow: 3, inSection: 1):
                identifier = "Reminder"
            default:
                identifier = "Setting"
            }

            let normalCell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! UITableViewCell

            switch indexPath {
            case NSIndexPath(forRow: 0, inSection: 1):
                normalCell.textLabel?.attributedText = attrTextFromString(cellStrings[indexPath.section][indexPath.row], withNewFlag: newMailCount > 0)
            case NSIndexPath(forRow: 2, inSection: 1):
                normalCell.textLabel?.attributedText = attrTextFromString(cellStrings[indexPath.section][indexPath.row], withNewFlag: newReplyCount > 0)
            case NSIndexPath(forRow: 3, inSection: 1):
                normalCell.textLabel?.attributedText = attrTextFromString(cellStrings[indexPath.section][indexPath.row], withNewFlag: newAtCount > 0)
            default:
                normalCell.textLabel?.text = cellStrings[indexPath.section][indexPath.row]
            }

            normalCell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            return normalCell
        }
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        if let indexPath = tableView.indexPathForCell(cell) {
            if let mbvc = segue.destinationViewController as? MailBoxViewController {
                switch indexPath {
                case NSIndexPath(forRow: 0, inSection: 1):
                    mbvc.inbox = true
                case NSIndexPath(forRow: 1, inSection: 1):
                    mbvc.inbox = false
                default:
                    break
                }
            } else if let rvc = segue.destinationViewController as? ReminderViewController {
                switch indexPath {
                case NSIndexPath(forRow: 2, inSection: 1):
                    rvc.replyMe = true
                case NSIndexPath(forRow: 3, inSection: 1):
                    rvc.replyMe = false
                default:
                    break
                }
            }
        }

    }
}
