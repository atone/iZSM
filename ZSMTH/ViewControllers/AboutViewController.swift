//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import RSTWebViewController

class AboutViewController: UITableViewController {

    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // add observer to font size change
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(AboutViewController.preferredFontSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)

        let width = UIScreen.screenWidth() < UIScreen.screenHeight() ? UIScreen.screenWidth() : UIScreen.screenHeight()
        let logoView = LogoView(frame: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(width)))
        tableView.tableHeaderView = logoView
    }

    // remove observer of notification
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: NSNotification) {
        updateUI()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath {
        case NSIndexPath(forRow: 0, inSection: 0):
            let urlAddress = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
            UIApplication.sharedApplication().openURL(NSURL(string: urlAddress)!)
        case NSIndexPath(forRow: 1, inSection: 0):
            let cevc = storyboard?.instantiateViewControllerWithIdentifier("ComposeEmailController") as! ComposeEmailController
            var versionText: String = ""
            if let infoDictionary = NSBundle.mainBundle().infoDictionary,
                appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
                appBuild = infoDictionary["CFBundleVersion"] as? String
            {
                versionText = "最水木(iZSM) \(appVersion)(\(appBuild))"
            }

            cevc.preTitle = "『\(versionText)』应用问题反馈"
            cevc.preReceiver = "atone"
            cevc.preContent = "\n\n设备类型: \(UIDevice.currentDevice().model)\n系统版本: \(UIDevice.currentDevice().systemName) \(UIDevice.currentDevice().systemVersion)\n应用版本: \(versionText)"
            let navigationController = UINavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .FormSheet
            presentViewController(navigationController, animated: true, completion: nil)
        case NSIndexPath(forRow: 2, inSection: 0):
            let urlAddress = "http://www.yunaitong.cn/2015/03/24/zsmth-released/"
            let webViewController = RSTWebViewController(address: urlAddress)
            webViewController.showsDoneButton = true
            let navigationController = NYNavigationController(rootViewController: webViewController)
            presentViewController(navigationController, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func updateUI() {
        rateLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        mailLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        websiteLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }


}
