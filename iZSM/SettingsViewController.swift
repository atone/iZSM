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

class SettingsViewController: UITableViewController {
    @IBOutlet weak var hideTopLabel: UILabel!
    @IBOutlet weak var showSignatureLabel: UILabel!
    @IBOutlet weak var newReplyFirstLabel: UILabel!
    @IBOutlet weak var backgroundTaskLabel: UILabel!
    @IBOutlet weak var clearCacheLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var aboutZSMLabel: UILabel!
    @IBOutlet weak var logoutLabel: UILabel!

    @IBOutlet weak var hideTopSwitch: UISwitch!
    @IBOutlet weak var showSignatureSwitch: UISwitch!
    @IBOutlet weak var newReplyFirstSwitch: UISwitch!
    @IBOutlet weak var backgroundTaskSwitch: UISwitch!


    let setting = AppSetting.sharedSetting
    
    var cache: YYImageCache?

    override func viewDidLoad() {
        super.viewDidLoad()
        cache = YYWebImageManager.shared().cache
        updateUI()
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
    }

    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: Notification) {
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
        showSignatureLabel.font = UIFont.preferredFont(forTextStyle: .body)
        newReplyFirstLabel.font = UIFont.preferredFont(forTextStyle: .body)
        backgroundTaskLabel.font = UIFont.preferredFont(forTextStyle: .body)
        clearCacheLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cacheSizeLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cacheSizeLabel.textColor = UIColor.lightGray
        var cacheSize = 0
        if let cache = cache {
            cacheSize = cache.diskCache.totalCost() / 1024 / 1024
        }
        cacheSizeLabel.text = "\(cacheSize) MB"
        aboutZSMLabel.font = UIFont.preferredFont(forTextStyle: .body)
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        logoutLabel.font = UIFont.boldSystemFont(ofSize: descriptor.pointSize)
        logoutLabel.textColor = UIColor.red

        // update switch states
        hideTopSwitch.isOn = setting.hideAlwaysOnTopThread
        showSignatureSwitch.isOn = setting.showSignature
        newReplyFirstSwitch.isOn = (setting.sortMode == .LaterPostFirst)
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
        if indexPath == IndexPath(row: 0, section: 2) {
            tableView.deselectRow(at: indexPath, animated: true)
            SVProgressHUD.show()
            DispatchQueue.global().async {
                self.cache?.memoryCache.removeAllObjects()
                self.cache?.diskCache.removeAllObjects()
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showSuccess(withStatus: "清除成功")
                    self.updateUI()
                }
            }
            
        }
    }
}
