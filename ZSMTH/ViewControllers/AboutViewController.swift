//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath {
        case NSIndexPath(forRow: 0, inSection: 0):
            let urlstr = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
            UIApplication.sharedApplication().openURL(NSURL(string: urlstr)!)
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func updateUI() {
        headerView.frame = CGRect(x: 0, y: 0, width: headerView.frame.width, height: CGFloat(UIScreen.screenHeight()/2))
        if let infoDictionary = NSBundle.mainBundle().infoDictionary,
            appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
            appBuild = infoDictionary["CFBundleVersion"] as? String
        {
            versionLabel.text = "最水木 iZSM \(appVersion)(\(appBuild))"
            versionLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        }
        rateLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        mailLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        websiteLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        
    }


}
