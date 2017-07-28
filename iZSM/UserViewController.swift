//
//  UserViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import MobileCoreServices
import RealmSwift
import SVProgressHUD

class UserViewController: NTTableViewController {
    
    private let kLabelIdentifier = "LabelIdentifier"
    private let labelContents = ["收件箱", "发件箱", "回复我", "提到我"]
    
    private let userInfoVC = UserInfoViewController()
    
    let api = SmthAPI()
    let setting = AppSetting.shared

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let scale: CGFloat = view.bounds.width < 350 ? 1 : 0.75
        let newSize = CGSize(width: view.bounds.width, height: view.bounds.width * scale)
        if userInfoVC.view.frame.size != newSize {
            userInfoVC.view.frame.size = newSize
            tableView.tableHeaderView = userInfoVC.view
        }
    }
    
    func setupUserInfoView() {
        userInfoVC.delegate = self
        userInfoVC.willMove(toParentViewController: self)
        addChildViewController(userInfoVC)
        userInfoVC.didMove(toParentViewController: self)
    }
    
    func updateUserInfoView() {
        if let username = setting.username {
            SMUserInfoUtil.querySMUser(for: username) { (user) in
                self.userInfoVC.updateUserInfoView(with: user)
            }
        }
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
        case 1:
            return 2
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let mbvc = MailBoxViewController()
            mbvc.inbox = true
            mbvc.userVC = self
            show(mbvc, sender: self)
        case IndexPath(row: 1, section: 0):
            let mbvc = MailBoxViewController()
            mbvc.inbox = false
            mbvc.userVC = self
            show(mbvc, sender: self)
        case IndexPath(row: 2, section: 0):
            let rvc = ReminderViewController()
            rvc.replyMe = true
            rvc.userVC = self
            show(rvc, sender: self)
        case IndexPath(row: 3, section: 0):
            let rvc = ReminderViewController()
            rvc.replyMe = false
            rvc.userVC = self
            show(rvc, sender: self)
        case IndexPath(row: 0, section: 1):
            let storyBoard = UIStoryboard(name: "Settings", bundle: nil)
            let settingsVC = storyBoard.instantiateViewController(withIdentifier: "SettingsViewController")
            show(settingsVC, sender: self)
        case IndexPath(row: 1, section: 1):
            let storyBoard = UIStoryboard(name: "Settings", bundle: nil)
            let supportVC = storyBoard.instantiateViewController(withIdentifier: "AboutViewController")
            show(supportVC, sender: self)
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
        case IndexPath(row: 0, section: 1):
            cell.textLabel?.attributedText = attrTextFromString(string: "设置", withNewFlag: false)
        case IndexPath(row: 1, section: 1):
            cell.textLabel?.attributedText = attrTextFromString(string: "支持与反馈", withNewFlag: false)
        default:
            cell.textLabel?.text = nil
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = AppTheme.shared.backgroundColor
        let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
        selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.selectedBackgroundView = selectedBackgroundView
        cell.selectedBackgroundView?.backgroundColor = AppTheme.shared.selectedBackgroundColor
        return cell
    }
    
    func attrTextFromString(string: String, withNewFlag flag: Bool) -> NSAttributedString {
        let normalColor = AppTheme.shared.textColor
        let redColor = AppTheme.shared.redColor
        let result = NSMutableAttributedString(string: string, attributes: [NSForegroundColorAttributeName: normalColor])
        if flag {
            result.append(NSAttributedString(string: " [新]", attributes: [NSForegroundColorAttributeName: redColor]))
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
                self.updateBadge(unreadCount: allCount)
                self.setting.mailCount = newMailCount
                self.setting.replyCount = newReplyCount
                self.setting.referCount = newReferCount
                self.tableView.reloadData()
            }
        }
    }
    
    func updateBadge(unreadCount: Int) {
        let count = max(unreadCount, 0)
        UIApplication.shared.applicationIconBadgeNumber = count
        if count > 0 {
            self.tabBarItem.badgeValue = "\(count)"
        } else {
            self.tabBarItem.badgeValue = nil
        }
    }
    
    @IBAction func logout(segue: UIStoryboardSegue) {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            self.api.logoutBBS()
            let realm = try! Realm()
            let readStatus = realm.objects(ArticleReadStatus.self)
            try! realm.write {
                realm.delete(readStatus)
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                SVProgressHUD.showSuccess(withStatus: "注销成功")
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

extension UserViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        let type = info[UIImagePickerControllerMediaType] as! String
        if type == kUTTypeImage as String {
            if let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
                networkActivityIndicatorStart()
                DispatchQueue.global().async {
                    if let user = self.api.modifyFaceImage(image: selectedImage) {
                        networkActivityIndicatorStop()
                        print("server response with new user info")
                        SMUserInfoUtil.updateSMUser(with: user) {
                            self.updateUserInfoView()
                        }
                    } else {
                        print("server did not response with new user info, try getting in 2 sec.")
                        sleep(2) // 等待2s
                        SMUserInfoUtil.querySMUser(for: self.setting.username!, forceUpdate: true) { (user) in
                            networkActivityIndicatorStop()
                            self.updateUserInfoView()
                        }
                    }
                    
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

extension UserViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        if setting.username == nil {
            return
        }
        let actionSheet = UIAlertController(title: "修改头像", message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let camera = UIAlertAction(title: "从图库中选择", style: .default) { [unowned self] action in
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.allowsEditing = true
                picker.sourceType = .photoLibrary
                picker.modalPresentationStyle = .formSheet
                self.present(picker, animated: true)
            }
            actionSheet.addAction(camera)
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let camera = UIAlertAction(title: "使用相机拍照", style: .default) { [unowned self] action in
                let picker = UIImagePickerController()
                picker.delegate = self
                picker.allowsEditing = true
                picker.sourceType = .camera
                self.present(picker, animated: true)
            }
            actionSheet.addAction(camera)
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        actionSheet.popoverPresentationController?.sourceView = imageView
        present(actionSheet, animated: true)
    }

    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {
        
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem) {
        
    }
    
    func shouldEnableSearch() -> Bool {
        return false
    }
    
    func shouldEnableCompose() -> Bool {
        return false
    }
}
