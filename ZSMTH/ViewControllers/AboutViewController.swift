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

    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var logoImageView: UIImageView! {
        didSet {
            if let imageView = logoImageView {
                imageView.layer.cornerRadius = imageView.frame.width / 8
                imageView.clipsToBounds = true
            }
        }
    }

    @IBOutlet weak var headerView: UIView!

    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath {
        case NSIndexPath(forRow: 0, inSection: 0):
            let urlAddress = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
            UIApplication.sharedApplication().openURL(NSURL(string: urlAddress)!)
        case NSIndexPath(forRow: 1, inSection: 0):
            let cevc = storyboard?.instantiateViewControllerWithIdentifier("ComposeEmailController") as! ComposeEmailController
            cevc.preTitle = "『\(versionLabel.text!)』应用问题反馈"
            cevc.preReceiver = "atone"
            cevc.preContent = "\n\n设备类型: \(UIDevice.currentDevice().model)\n系统版本: \(UIDevice.currentDevice().systemName) \(UIDevice.currentDevice().systemVersion)\n应用版本: \(versionLabel.text!)"
            let navigationController = UINavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .FormSheet
            presentViewController(navigationController, animated: true, completion: nil)
        case NSIndexPath(forRow: 2, inSection: 0):
            let urlAddress = "http://www.yunaitong.cn/blog/2015/03/24/zsmth-released/"
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
        let width = UIScreen.screenWidth() < UIScreen.screenHeight() ? UIScreen.screenWidth() : UIScreen.screenHeight()
        headerView.frame = CGRect(x: 0, y: 0, width: CGFloat(UIScreen.screenWidth()), height: CGFloat(width))
        if let infoDictionary = NSBundle.mainBundle().infoDictionary,
            appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
            appBuild = infoDictionary["CFBundleVersion"] as? String
        {
            versionLabel.text = "最水木(iZSM) \(appVersion)(\(appBuild))"
            versionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        }
        rateLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        mailLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        websiteLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }


}
