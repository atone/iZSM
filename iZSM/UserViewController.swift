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
import TZImagePickerController

class UserViewController: NTTableViewController {
    
    private let kLabelIdentifier = "LabelIdentifier"
    private let labelContents = ["收件箱", "发件箱", "回复我", "提到我"]
    
    private let userInfoVC = UserInfoViewController()
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    private let msgCenter = MessageCenter.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.reloadData()
        setupUserInfoView()
        
        
        
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        // add observer to update unread message count
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateUnreadMessage(_:)),
                                               name: MessageCenter.kUpdateMessageCountNotification,
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
        userInfoVC.willMove(toParent: self)
        addChild(userInfoVC)
        userInfoVC.didMove(toParent: self)
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
        msgCenter.checkUnreadMessage()
    }
    
    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // handle font size change
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
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
            let flag = (index.row == 0 && msgCenter.mailCount > 0)
            || (index.row == 2 && msgCenter.replyCount > 0)
            || (index.row == 3 && msgCenter.referCount > 0)
            cell.textLabel?.attributedText = attrTextFromString(string: labelContents[index.row], withNewFlag: flag)
        case IndexPath(row: 0, section: 1):
            cell.textLabel?.attributedText = attrTextFromString(string: "设置", withNewFlag: false)
        case IndexPath(row: 1, section: 1):
            cell.textLabel?.attributedText = attrTextFromString(string: "支持与反馈", withNewFlag: false)
        default:
            cell.textLabel?.text = nil
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func attrTextFromString(string: String, withNewFlag flag: Bool) -> NSAttributedString {
        let normalColor = UIColor.label
        let redColor = UIColor.systemRed
        let result = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: normalColor])
        if flag {
            result.append(NSAttributedString(string: " [新]", attributes: [NSAttributedString.Key.foregroundColor: redColor]))
        }
        result.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSMakeRange(0, result.length))
        return result
    }
    
    @objc private func updateUnreadMessage(_ notification: Notification) {
        updateUI()
    }
    
    func updateUI() {
        let count = msgCenter.mailCount + msgCenter.replyCount + msgCenter.referCount
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            if count > 0 {
                self.tabBarItem.badgeValue = "\(count)"
            } else {
                self.tabBarItem.badgeValue = nil
            }
            self.tableView.reloadData()
        }
    }
    
    @IBAction func logout(_ segue: UIStoryboardSegue) {
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

extension UserViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        if let selectedImage = photos.first {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                if let user = self.api.modifyFaceImage(image: selectedImage) {
                    networkActivityIndicatorStop()
                    dPrint("server response with new user info")
                    SMUserInfoUtil.updateSMUser(with: user) {
                        self.updateUserInfoView()
                    }
                } else {
                    dPrint("server did not response with new user info, try getting in 2 sec.")
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

extension UserViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        if setting.username == nil {
            return
        }
        let imagePicker = TZImagePickerController(maxImagesCount: 1, delegate: self)!
        imagePicker.modalPresentationStyle = .formSheet
        imagePicker.naviBgColor = navigationController?.navigationBar.barTintColor
        imagePicker.naviTitleColor = navigationController?.navigationBar.tintColor
        imagePicker.allowPickingVideo = false
        imagePicker.allowPickingOriginalPhoto = false
        imagePicker.allowCrop = true
        present(imagePicker, animated: true)
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
