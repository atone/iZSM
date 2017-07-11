//
//  UserViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import RealmSwift
import SVProgressHUD

class UserViewController: UITableViewController {
    
    private let kLabelIdentifier = "LabelIdentifier"
    private let labelContents = ["收件箱", "发件箱", "回复我", "提到我"]
    
    private let userInfoVC = UserInfoViewController()
    
    let api = SmthAPI()
    let setting = AppSetting.sharedSetting

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.reloadData()
        setupUserInfoView()
        
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
    }
    
    func setupUserInfoView() {
        userInfoVC.delegate = self
        userInfoVC.willMove(toParentViewController: self)
        tableView.tableHeaderView = userInfoVC.view
        addChildViewController(userInfoVC)
        userInfoVC.didMove(toParentViewController: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        userInfoVC.view.frame = CGRect(x: 0,
                                       y: 0,
                                       width: UIScreen.screenWidth(),
                                       height: UIScreen.screenWidth() * 3 / 4)
    }
    
    func updateUserInfoView() {
        if let username = setting.username {
            SMUserInfoUtil.querySMUser(for: username) { (user) in
                self.userInfoVC.updateUserInfoView(with: user)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        updateUserInfoView()
        checkUnreadMessage()
    }
    
    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // handle font size change
    func preferredFontSizeChanged(notification: Notification) {
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return labelContents.count
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let mbvc = MailBoxViewController()
            mbvc.inbox = true
            show(mbvc, sender: self)
        case IndexPath(row: 1, section: 0):
            let mbvc = MailBoxViewController()
            mbvc.inbox = false
            show(mbvc, sender: self)
        case IndexPath(row: 2, section: 0):
            let rvc = ReminderViewController()
            rvc.replyMe = true
            show(rvc, sender: self)
        case IndexPath(row: 3, section: 0):
            let rvc = ReminderViewController()
            rvc.replyMe = false
            show(rvc, sender: self)
        case IndexPath(row: 0, section: 1):
            let storyBoard = UIStoryboard(name: "Settings", bundle: nil)
            let settingsVC = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
            show(settingsVC, sender: self)
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        if let newCell = tableView.dequeueReusableCell(withIdentifier: kLabelIdentifier) {
            cell = newCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: kLabelIdentifier)
        }
        // Configure the cell...
        switch indexPath {
        case let index where index.section == 0:
            let flag = (index.row == 0 && setting.mailCount > 0)
            || (index.row == 2 && setting.replyCount > 0)
            || (index.row == 3 && setting.referCount > 0)
            cell.textLabel?.attributedText = attrTextFromString(string: labelContents[index.row], withNewFlag: flag)
        case let index where index.section == 1:
            cell.textLabel?.attributedText = attrTextFromString(string: "设置", withNewFlag: false)
        default:
            cell.textLabel?.text = nil
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func attrTextFromString(string: String, withNewFlag flag: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString(string: string)
        if flag {
            result.append(NSAttributedString(string: " [新]", attributes: [NSForegroundColorAttributeName: UIColor.red]))
        }
        result.addAttribute(NSFontAttributeName, value: UIFont.preferredFont(forTextStyle: .body), range: NSMakeRange(0, result.length))
        return result
    }
    
    func checkUnreadMessage() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            let newMailCount = self.api.getMailStatus()?.newCount ?? 0
            let newReplyCount = self.api.getReferCount(mode: .ReplyToMe)?.newCount ?? 0
            let newReferCount = self.api.getReferCount(mode: .AtMe)?.newCount ?? 0
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                let allCount = newMailCount + newReplyCount + newReferCount
                UIApplication.shared.applicationIconBadgeNumber = allCount
                if allCount > 0 {
                    self.tabBarItem?.badgeValue = "\(allCount)"
                } else {
                    self.tabBarItem?.badgeValue = nil
                }
                self.setting.mailCount = newMailCount
                self.setting.replyCount = newReplyCount
                self.setting.referCount = newReferCount
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func logout(segue: UIStoryboardSegue) {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            self.api.logoutBBS()
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if self.api.errorCode == 0 {
                    SVProgressHUD.showSuccess(withStatus: "注销成功")
                } else if self.api.errorDescription != nil && self.api.errorDescription! != "" {
                    SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
                self.setting.username = nil
                self.setting.password = nil
                self.setting.accessToken = nil
                self.setting.mailCount = 0
                self.setting.replyCount = 0
                self.setting.referCount = 0
                self.userInfoVC.updateUserInfoView(with: nil)
                NotificationCenter.default.post(name: BaseTableViewController.kNeedRefreshNotification,
                                                object: nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.tabBarController?.selectedIndex = 0
                }
            }
        }
    }
}

extension UserViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {
        
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem) {
        if let userID = controller.user?.id {
            dismiss(animated: true, completion: nil)
            let cevc = ComposeEmailController()
            cevc.preReceiver = userID
            let navigationController = UINavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func shouldEnableSearch() -> Bool {
        return false
    }
    
    func shouldEnableCompose() -> Bool {
        return false
    }
}
