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
import CoreData
import SmthConnection

class SettingsViewController: NTTableViewController {
    @IBOutlet weak var hideTopLabel: UILabel!
    @IBOutlet weak var showSignatureLabel: UILabel!
    @IBOutlet weak var newReplyFirstLabel: UILabel!
    @IBOutlet weak var rememberLastLabel: UILabel!
    @IBOutlet weak var addDeviceSignatureLabel: UILabel!
    @IBOutlet weak var displayModeLabel: UILabel!
    @IBOutlet weak var customHotSectionLabel: UILabel!
    @IBOutlet weak var boldFontLabel: UILabel!
    @IBOutlet weak var showAvatarLabel: UILabel!
    @IBOutlet weak var noPicModeLabel: UILabel!
    @IBOutlet weak var backgroundTaskLabel: UILabel!
    @IBOutlet weak var clearReadingStatusLabel: UILabel!
    @IBOutlet weak var clearCacheLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var compatibilityLabel: UILabel!
    @IBOutlet weak var logoutLabel: UILabel!

    @IBOutlet weak var hideTopSwitch: UISwitch!
    @IBOutlet weak var showSignatureSwitch: UISwitch!
    @IBOutlet weak var newReplyFirstSwitch: UISwitch!
    @IBOutlet weak var rememberLastSwitch: UISwitch!
    @IBOutlet weak var addDeviceSignatureSwitch: UISwitch!
    @IBOutlet weak var boldFontSwitch: UISwitch!
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
            setting.sortMode = .newFirst
        } else {
            setting.sortMode = .oldFirst
        }
    }
    
    @IBAction func rememberLastChanged(_ sender: UISwitch) {
        setting.rememberLast = sender.isOn
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
    
    @IBAction func boldFontChanged(_ sender: UISwitch) {
        setting.useBoldFont = sender.isOn
        NotificationCenter.default.post(Notification(name: SettingsViewController.fontScaleDidChangeNotification))
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
        addDeviceSignatureLabel.font = font
        addDeviceSignatureLabel.textColor = UIColor(named: "MainText")
        displayModeLabel.font = font
        displayModeLabel.textColor = UIColor(named: "MainText")
        customHotSectionLabel.font = font
        customHotSectionLabel.textColor = UIColor(named: "MainText")
        boldFontLabel.font = font
        boldFontLabel.textColor = UIColor(named: "MainText")
        showAvatarLabel.font = font
        showAvatarLabel.textColor = UIColor(named: "MainText")
        noPicModeLabel.font = font
        noPicModeLabel.textColor = UIColor(named: "MainText")
        backgroundTaskLabel.font = font
        backgroundTaskLabel.textColor = UIColor(named: "MainText")
        clearReadingStatusLabel.font = font
        clearReadingStatusLabel.textColor = UIColor(named: "MainText")
        clearCacheLabel.font = font
        clearCacheLabel.textColor = UIColor(named: "MainText")
        cacheSizeLabel.font = font
        cacheSizeLabel.textColor = UIColor.secondaryLabel
        var cacheSize = 0
        if let cache = cache {
            cacheSize = cache.diskCache.totalCost() / 1024 / 1024
        }
        cacheSizeLabel.text = "\(cacheSize) MB"
        compatibilityLabel.font = font
        compatibilityLabel.textColor = UIColor(named: "MainText")
        logoutLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize * setting.fontScale)
        logoutLabel.textColor = UIColor.systemRed

        // update switch states
        hideTopSwitch.isOn = setting.hideAlwaysOnTopThread
        showSignatureSwitch.isOn = setting.showSignature
        newReplyFirstSwitch.isOn = (setting.sortMode == .newFirst)
        rememberLastSwitch.isOn = setting.rememberLast
        addDeviceSignatureSwitch.isOn = setting.addDeviceSignature
        displayModeSegmentedControl.selectedSegmentIndex = setting.displayMode.rawValue
        fontSizeSlider.value = Float(fontScaleIndex)
        boldFontSwitch.isOn = setting.useBoldFont
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == IndexPath(row: 0, section: 4) {
            tableView.deselectRow(at: indexPath, animated: true)
            SVProgressHUD.show()
            let container = CoreDataHelper.shared.persistentContainer
            container.performBackgroundTask { context in
                let deleteUserInfoRequest = NSBatchDeleteRequest(fetchRequest: SMUserInfo.fetchRequest())
                let deleteBoardInfoRequest = NSBatchDeleteRequest(fetchRequest: SMBoardInfo.fetchRequest())
                let deleteReadStatusRequest = NSBatchDeleteRequest(fetchRequest: ArticleReadStatus.fetchRequest())
                do {
                    try context.execute(deleteUserInfoRequest)
                    try context.execute(deleteBoardInfoRequest)
                    try context.execute(deleteReadStatusRequest)
                } catch {
                    dPrint(error.localizedDescription)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "清除成功")
                    self.updateUI()
                }
            }
        } else if indexPath == IndexPath(row: 1, section: 4) {
            tableView.deselectRow(at: indexPath, animated: true)
            SVProgressHUD.show()
            DispatchQueue.global().async {
                self.cache?.memoryCache.removeAllObjects()
                self.cache?.diskCache.removeAllObjects()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "清除成功")
                    self.updateUI()
                }
            }
        }
    }
}
