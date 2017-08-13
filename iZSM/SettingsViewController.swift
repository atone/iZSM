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
    @IBOutlet weak var displayModeLabel: UILabel!
    @IBOutlet weak var displayModeCell: UITableViewCell!
    @IBOutlet weak var showAvatarLabel: UILabel!
    @IBOutlet weak var showAvatarCell: UITableViewCell!
    @IBOutlet weak var noPicModeLabel: UILabel!
    @IBOutlet weak var noPicModeCell: UITableViewCell!
    @IBOutlet weak var nightModelLabel: UILabel!
    @IBOutlet weak var nightModelCell: UITableViewCell!
    @IBOutlet weak var shakeToSwitchLabel: UILabel!
    @IBOutlet weak var shakeToSwitchCell: UITableViewCell!
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
    @IBOutlet weak var showAvatarSwitch: UISwitch!
    @IBOutlet weak var noPicModeSwitch: UISwitch!
    @IBOutlet weak var nightModeSwitch: UISwitch!
    @IBOutlet weak var shakeToSwitchSwitch: UISwitch!
    @IBOutlet weak var backgroundTaskSwitch: UISwitch!
    @IBOutlet weak var displayModeSegmentedControl: UISegmentedControl!


    let setting = AppSetting.shared
    let theme = AppTheme.shared
    
    var cache: YYImageCache?

    override func viewDidLoad() {
        super.viewDidLoad()
        cache = YYWebImageManager.shared().cache
        updateUI()
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
    }

    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(_ notification: Notification) {
        updateUI()
    }

    @IBAction func hideTopChanged(sender: UISwitch) {
        setting.hideAlwaysOnTopThread = sender.isOn
    }

    @IBAction func showSignatureChanged(sender: UISwitch) {
        setting.showSignature = sender.isOn
    }
    
    @IBAction func newReplyFirstChanged(sender: UISwitch) {
        if sender.isOn {
            setting.sortMode = .LaterPostFirst
        } else {
            setting.sortMode = .Normal
        }
    }
    
    @IBAction func rememberLastChanged(sender: UISwitch) {
        setting.rememberLast = sender.isOn
        if !sender.isOn {
            let realm = try! Realm()
            let readStatus = realm.objects(ArticleReadStatus.self)
            try! realm.write {
                realm.delete(readStatus)
            }
        }
    }
    
    @IBAction func portraitLockChanged(sender: UISwitch) {
        setting.portraitLock = sender.isOn
    }
    
    @IBAction func displayModeChanged(sender: UISegmentedControl) {
        setting.displayMode = AppSetting.DisplayMode(rawValue: sender.selectedSegmentIndex)!
    }
    
    @IBAction func showAvatarChanged(sender: UISwitch) {
        setting.showAvatar = sender.isOn
    }
    
    @IBAction func noPicModeChanged(sender: UISwitch) {
        setting.noPicMode = sender.isOn
        if sender.isOn {
            showAvatarSwitch.setOn(false, animated: true)
            showAvatarSwitch.isEnabled = false
        } else {
            showAvatarSwitch.setOn(setting.showAvatar, animated: true)
            showAvatarSwitch.isEnabled = true
        }
    }
    
    @IBAction func nightModeChanged(sender: UISwitch) {
        setting.nightMode = sender.isOn
        NotificationCenter.default.post(name: AppTheme.kAppThemeChangedNotification, object: nil)
    }
    
    @IBAction func shakeToSwitchChanged(sender: UISwitch) {
        setting.shakeToSwitch = sender.isOn
    }

    @IBAction func backgroundTaskChanged(sender: UISwitch) {
        setting.backgroundTaskEnabled = sender.isOn
        if sender.isOn {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }

    func updateUI() {
        // update label fonts
        hideTopLabel.font = UIFont.preferredFont(forTextStyle: .body)
        hideTopLabel.textColor = theme.textColor
        showSignatureLabel.font = UIFont.preferredFont(forTextStyle: .body)
        showSignatureLabel.textColor = theme.textColor
        newReplyFirstLabel.font = UIFont.preferredFont(forTextStyle: .body)
        newReplyFirstLabel.textColor = theme.textColor
        rememberLastLabel.font = UIFont.preferredFont(forTextStyle: .body)
        rememberLastLabel.textColor = theme.textColor
        portraitLockLabel.font = UIFont.preferredFont(forTextStyle: .body)
        portraitLockLabel.textColor = theme.textColor
        displayModeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        displayModeLabel.textColor = theme.textColor
        showAvatarLabel.font = UIFont.preferredFont(forTextStyle: .body)
        showAvatarLabel.textColor = theme.textColor
        noPicModeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        noPicModeLabel.textColor = theme.textColor
        nightModelLabel.font = UIFont.preferredFont(forTextStyle: .body)
        nightModelLabel.textColor = theme.textColor
        shakeToSwitchLabel.font = UIFont.preferredFont(forTextStyle: .body)
        shakeToSwitchLabel.textColor = theme.textColor
        backgroundTaskLabel.font = UIFont.preferredFont(forTextStyle: .body)
        backgroundTaskLabel.textColor = theme.textColor
        clearCacheLabel.font = UIFont.preferredFont(forTextStyle: .body)
        clearCacheLabel.textColor = theme.textColor
        cacheSizeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cacheSizeLabel.textColor = theme.lightTextColor
        var cacheSize = 0
        if let cache = cache {
            cacheSize = cache.diskCache.totalCost() / 1024 / 1024
        }
        cacheSizeLabel.text = "\(cacheSize) MB"
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        logoutLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
        logoutLabel.textColor = theme.redColor

        // update switch states
        UISwitch.appearance().onTintColor = theme.tintColor
        hideTopSwitch.isOn = setting.hideAlwaysOnTopThread
        showSignatureSwitch.isOn = setting.showSignature
        newReplyFirstSwitch.isOn = (setting.sortMode == .LaterPostFirst)
        rememberLastSwitch.isOn = setting.rememberLast
        portraitLockSwitch.isOn = setting.portraitLock
        displayModeSegmentedControl.selectedSegmentIndex = setting.displayMode.rawValue
        noPicModeSwitch.isOn = setting.noPicMode
        if setting.noPicMode {
            showAvatarSwitch.isOn = false
            showAvatarSwitch.isEnabled = false
        } else {
            showAvatarSwitch.isOn = setting.showAvatar
            showAvatarSwitch.isEnabled = true
        }
        nightModeSwitch.isOn = setting.nightMode
        shakeToSwitchSwitch.isOn = setting.shakeToSwitch
        backgroundTaskSwitch.isOn = setting.backgroundTaskEnabled
        
        hideTopCell.backgroundColor = theme.backgroundColor
        showSignatureCell.backgroundColor = theme.backgroundColor
        newReplyFirstCell.backgroundColor = theme.backgroundColor
        rememberLastCell.backgroundColor = theme.backgroundColor
        portraitLockCell.backgroundColor = theme.backgroundColor
        displayModeCell.backgroundColor = theme.backgroundColor
        showAvatarCell.backgroundColor = theme.backgroundColor
        noPicModeCell.backgroundColor = theme.backgroundColor
        nightModelCell.backgroundColor = theme.backgroundColor
        shakeToSwitchCell.backgroundColor = theme.backgroundColor
        backgroundTaskCell.backgroundColor = theme.backgroundColor
        clearCacheCell.backgroundColor = theme.backgroundColor
        logoutCell.backgroundColor = theme.backgroundColor
    }
    
    override func changeColor() {
        super.changeColor()
        updateUI()
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 4) {
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
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerFooterView = view as? UITableViewHeaderFooterView {
            headerFooterView.textLabel?.textColor = AppTheme.shared.lightTextColor
        }
    }
}
