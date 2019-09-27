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
    @IBOutlet weak var showSignatureLabel: UILabel!
    @IBOutlet weak var newReplyFirstLabel: UILabel!
    @IBOutlet weak var rememberLastLabel: UILabel!
    @IBOutlet weak var portraitLockLabel: UILabel!
    @IBOutlet weak var addDeviceSignatureLabel: UILabel!
    @IBOutlet weak var displayModeLabel: UILabel!
    @IBOutlet weak var customHotSectionLabel: UILabel!
    @IBOutlet weak var showAvatarLabel: UILabel!
    @IBOutlet weak var noPicModeLabel: UILabel!
    @IBOutlet weak var backgroundTaskLabel: UILabel!
    @IBOutlet weak var clearCacheLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var logoutLabel: UILabel!

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
    @IBOutlet weak var fontSizeSlider: UISlider!


    let setting = AppSetting.shared
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    static let fontScaleDidChangeNotification = Notification.Name("fontScaleDidChangeNotification")
    
    var fontScaleIndex: Int {
        get { return setting.customFontScaleIndex }
        set {
            if newValue != setting.customFontScaleIndex {
                setting.customFontScaleIndex = newValue
                feedbackGenerator.impactOccurred()
                NotificationCenter.default.post(Notification(name: SettingsViewController.fontScaleDidChangeNotification))
            }
        }
    }
    
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: SettingsViewController.fontScaleDidChangeNotification,
                                               object: nil)
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
    
    @IBAction func fontSizeScaleChanged(_ sender: UISlider) {
        let index = Int(sender.value + 0.5)
        sender.setValue(Float(index), animated: false)
        fontScaleIndex = index
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
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let font = UIFont.systemFont(ofSize: descriptor.pointSize * setting.fontScale)
        hideTopLabel.font = font
        hideTopLabel.textColor = UIColor(named: "MainText")
        showSignatureLabel.font = font
        showSignatureLabel.textColor = UIColor(named: "MainText")
        newReplyFirstLabel.font = font
        newReplyFirstLabel.textColor = UIColor(named: "MainText")
        rememberLastLabel.font = font
        rememberLastLabel.textColor = UIColor(named: "MainText")
        portraitLockLabel.font = font
        portraitLockLabel.textColor = UIColor(named: "MainText")
        addDeviceSignatureLabel.font = font
        addDeviceSignatureLabel.textColor = UIColor(named: "MainText")
        displayModeLabel.font = font
        displayModeLabel.textColor = UIColor(named: "MainText")
        customHotSectionLabel.font = font
        customHotSectionLabel.textColor = UIColor(named: "MainText")
        showAvatarLabel.font = font
        showAvatarLabel.textColor = UIColor(named: "MainText")
        noPicModeLabel.font = font
        noPicModeLabel.textColor = UIColor(named: "MainText")
        backgroundTaskLabel.font = font
        backgroundTaskLabel.textColor = UIColor(named: "MainText")
        clearCacheLabel.font = font
        clearCacheLabel.textColor = UIColor(named: "MainText")
        cacheSizeLabel.font = font
        cacheSizeLabel.textColor = UIColor.secondaryLabel
        var cacheSize = 0
        if let cache = cache {
            cacheSize = cache.diskCache.totalCost() / 1024 / 1024
        }
        cacheSizeLabel.text = "\(cacheSize) MB"
        logoutLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize * setting.fontScale)
        logoutLabel.textColor = UIColor.systemRed

        // update switch states
        hideTopSwitch.isOn = setting.hideAlwaysOnTopThread
        showSignatureSwitch.isOn = setting.showSignature
        newReplyFirstSwitch.isOn = (setting.sortMode == .LaterPostFirst)
        rememberLastSwitch.isOn = setting.rememberLast
        portraitLockSwitch.isOn = setting.portraitLock
        addDeviceSignatureSwitch.isOn = setting.addDeviceSignature
        displayModeSegmentedControl.selectedSegmentIndex = setting.displayMode.rawValue
        fontSizeSlider.value = Float(fontScaleIndex)
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
}
