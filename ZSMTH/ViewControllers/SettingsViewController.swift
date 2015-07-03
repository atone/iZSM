//
//  SettingsViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/27.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet weak var hideTopLabel: UILabel!
    @IBOutlet weak var showSignatureLabel: UILabel!
    @IBOutlet weak var backgroundTaskLabel: UILabel!
    @IBOutlet weak var aboutZSMLabel: UILabel!

    @IBOutlet weak var hideTopSwitch: UISwitch!
    @IBOutlet weak var showSignatureSwitch: UISwitch!
    @IBOutlet weak var backgroundTaskSwitch: UISwitch!


    let setting = AppSetting.sharedSetting()

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
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
        updateUI()
    }

    @IBAction func hideTopChanged(sender: UISwitch) {
        setting.hideAlwaysOnTopThread = sender.on
    }

    @IBAction func showSignatureChanged(sender: UISwitch) {
        setting.showSignature = sender.on
    }

    @IBAction func backgroundTaskChanged(sender: UISwitch) {
        setting.backgroundTaskEnabled = sender.on
        if sender.on {
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        } else {
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }

    func updateUI() {
        // update label fonts
        hideTopLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        showSignatureLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        backgroundTaskLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        aboutZSMLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)

        // update switch states
        hideTopSwitch.on = setting.hideAlwaysOnTopThread
        showSignatureSwitch.on = setting.showSignature
        backgroundTaskSwitch.on = setting.backgroundTaskEnabled
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(selectedRow, animated: true)
        }
    }
}
