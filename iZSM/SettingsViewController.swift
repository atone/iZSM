//
//  SettingsViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/27.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import YYKit
import SVProgressHUD
import RealmSwift

class SettingsViewController: NTTableViewController {
    @IBOutlet weak var hideTopLabel: UILabel!
    @IBOutlet weak var hideTopCell: UITableViewCell!
    @IBOutlet weak var showSignatureLabel: UILabel!
    @IBOutlet weak var showSignatureCell: UITableViewCell!
    @IBOutlet weak var newReplyFirstLabel: UILabel!
    @IBOutlet weak var newReplyFirstCell: UITableViewCell!
    @IBOutlet weak var rememberLastLabel: UILabel!
    @IBOutlet weak var rememberLastCell: UITableViewCell!
    @IBOutlet weak var portraitLockLabel: UILabel!
    @IBOutlet weak var portraitLockCell: UITableViewCell!
    @IBOutlet weak var addDeviceSignatureLabel: UILabel!
    @IBOutlet weak var addDeviceSignatureCell: UITableViewCell!
    @IBOutlet weak var displayModeLabel: UILabel!
    @IBOutlet weak var displayModeCell: UITableViewCell!
    @IBOutlet weak var showAvatarLabel: UILabel!
    @IBOutlet weak var showAvatarCell: UITableViewCell!
    @IBOutlet weak var noPicModeLabel: UILabel!
    @IBOutlet weak var noPicModeCell: UITableViewCell!
    @IBOutlet weak var backgroundTaskLabel: UILabel!
    @IBOutlet weak var backgroundTaskCell: UITableViewCell!
    @IBOutlet weak var clearCacheLabel: UILabel!
    @IBOutlet weak var clearCacheCell: UITableViewCell!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var logoutLabel: UILabel!
    @IBOutlet weak var logoutCell: UITableViewCell!

    @IBOutlet weak var hideTopSwitch: UISwitch!
    @IBOutlet weak var showSignatureSwitch: UISwitch!
    @IBOutlet weak var newReplyFirstSwitch: UISwitch!
    @IBOutlet weak var rememberLastSwitch: UISwitch!
    @IBOutlet weak var portraitLockSwitch: UISwitch!
    @IBOutlet weak var addDeviceSignatureSwitch: UISwitch!
    @IBOutlet weak var showAvatarSwitch: UISwitch!
    @IBOutlet weak var noPicModeSwitch: UISwitch!
    @IBOutlet weak var backgroundTaskSwitch: UISwitch!
    @IBOutlet weak var displayModeSegmentedControl: UISegmentedControl!


    let setting = AppSetting.shared
    
    var cache: YYImageCache?

    override func viewDidLoad() {
        super.viewDidLoad()
        cache = YYWebImageManager.shared().cache
        updateUI()
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // handle font size change
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
        updateUI()
    }

    @IBAction func hideTopChanged(_ sender: UISwitch) {
        setting.hideAlwaysOnTopThread = sender.isOn
    }

    @IBAction func showSignatureChanged(_ sender: UISwitch) {
        setting.showSignature = sender.isOn
    }
    
    @IBAction func newReplyFirstChanged(_ sender: UISwitch) {
        if sender.isOn {
            setting.sortMode = .LaterPostFirst
        } else {
            setting.sortMode = .Normal
        }
    }
    
    @IBAction func rememberLastChanged(_ sender: UISwitch) {
        setting.rememberLast = sender.isOn
        if !sender.isOn {
            let realm = try! Realm()
            let readStatus = realm.objects(ArticleReadStatus.self)
            try! realm.write {
                realm.delete(readStatus)
            }
        }
    }
    
    @IBAction func portraitLockChanged(_ sender: UISwitch) {
        setting.portraitLock = sender.isOn
    }
    
    @IBAction func addDeviceSignatureChanged(_ sender: UISwitch) {
        setting.addDeviceSignature = sender.isOn
    }
    
    @IBAction func displayModeChanged(_ sender: UISegmentedControl) {
        setting.displayMode = AppSetting.DisplayMode(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func showAvatarChanged(_ sender: UISwitch) {
        setting.showAvatar = sender.isOn
    }
    
    @IBAction func noPicModeChanged(_ sender: UISwitch) {
        setting.noPicMode = sender.isOn
        if sender.isOn {
            showAvatarSwitch.setOn(false, animated: true)
            showAvatarSwitch.isEnabled = false
        } else {
            showAvatarSwitch.setOn(setting.showAvatar, animated: true)
            showAvatarSwitch.isEnabled = true
        }
    }

    @IBAction func backgroundTaskChanged(_ sender: UISwitch) {
        setting.backgroundTaskEnabled = sender.isOn
    }

    func updateUI() {
        // update label fonts
        hideTopLabel.font = UIFont.preferredFont(forTextStyle: .body)
        hideTopLabel.textColor = UIColor.label
        showSignatureLabel.font = UIFont.preferredFont(forTextStyle: .body)
        showSignatureLabel.textColor = UIColor.label
        newReplyFirstLabel.font = UIFont.preferredFont(forTextStyle: .body)
        newReplyFirstLabel.textColor = UIColor.label
        rememberLastLabel.font = UIFont.preferredFont(forTextStyle: .body)
        rememberLastLabel.textColor = UIColor.label
        portraitLockLabel.font = UIFont.preferredFont(forTextStyle: .body)
        portraitLockLabel.textColor = UIColor.label
        addDeviceSignatureLabel.font = UIFont.preferredFont(forTextStyle: .body)
        addDeviceSignatureLabel.textColor = UIColor.label
        displayModeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        displayModeLabel.textColor = UIColor.label
        showAvatarLabel.font = UIFont.preferredFont(forTextStyle: .body)
        showAvatarLabel.textColor = UIColor.label
        noPicModeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        noPicModeLabel.textColor = UIColor.label
        backgroundTaskLabel.font = UIFont.preferredFont(forTextStyle: .body)
        backgroundTaskLabel.textColor = UIColor.label
        clearCacheLabel.font = UIFont.preferredFont(forTextStyle: .body)
        clearCacheLabel.textColor = UIColor.label
        cacheSizeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cacheSizeLabel.textColor = UIColor.secondaryLabel
        var cacheSize = 0
        if let cache = cache {
            cacheSize = cache.diskCache.totalCost() / 1024 / 1024
        }
        cacheSizeLabel.text = "\(cacheSize) MB"
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        logoutLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
        logoutLabel.textColor = UIColor.systemRed

        // update switch states
        UISwitch.appearance().onTintColor = UIColor(named: "SmthColor")
        hideTopSwitch.isOn = setting.hideAlwaysOnTopThread
        showSignatureSwitch.isOn = setting.showSignature
        newReplyFirstSwitch.isOn = (setting.sortMode == .LaterPostFirst)
        rememberLastSwitch.isOn = setting.rememberLast
        portraitLockSwitch.isOn = setting.portraitLock
        addDeviceSignatureSwitch.isOn = setting.addDeviceSignature
        displayModeSegmentedControl.selectedSegmentIndex = setting.displayMode.rawValue
        noPicModeSwitch.isOn = setting.noPicMode
        if setting.noPicMode {
            showAvatarSwitch.isOn = false
            showAvatarSwitch.isEnabled = false
        } else {
            showAvatarSwitch.isOn = setting.showAvatar
            showAvatarSwitch.isEnabled = true
        }
        backgroundTaskSwitch.isOn = setting.backgroundTaskEnabled
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 3) {
            tableView.deselectRow(at: indexPath, animated: true)
            SVProgressHUD.show()
            DispatchQueue.global().async {
                self.cache?.memoryCache.removeAllObjects()
                self.cache?.diskCache.removeAllObjects()
                let realm = try! Realm()
                try! realm.write {
                    realm.deleteAll()
                }
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "清除成功")
                    self.updateUI()
                }
            }
        }
    }
}
