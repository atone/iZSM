//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class AboutViewController: UITableViewController {

    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
            selector: #selector(preferredFontSizeChanged(notification:)),
            name: .UIContentSizeCategoryDidChange,
            object: nil)

        let width = UIScreen.screenWidth() < UIScreen.screenHeight() ? UIScreen.screenWidth() : UIScreen.screenHeight()
        let logoView = LogoView(frame: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(width)))
        tableView.tableHeaderView = logoView
    }

    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: Notification) {
        updateUI()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            let urlAddress = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
            UIApplication.shared.openURL(URL(string: urlAddress)!)
        case IndexPath(row: 1, section: 0):
            let cevc = ComposeEmailController()
            var versionText: String = ""
            if
                let infoDictionary = Bundle.main.infoDictionary,
                let appVersion = infoDictionary["CFBundleShortVersionString"] as? String,
                let appBuild = infoDictionary["CFBundleVersion"] as? String
            {
                versionText = "最水木(iZSM) \(appVersion)(\(appBuild))"
            }

            cevc.preTitle = "『\(versionText)』应用问题反馈"
            cevc.preReceiver = "atone"
            cevc.preContent = "\n\n设备类型: \(UIDevice.current.model)\n系统版本: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n应用版本: \(versionText)"
            let navigationController = UINavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
        case IndexPath(row: 2, section: 0):
            let urlAddress = "http://www.yunaitong.cn/zsmth-released.html"
            let webViewController = SFSafariViewController(url: URL(string: urlAddress)!)
            present(webViewController, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func updateUI() {
        rateLabel.font = UIFont.preferredFont(forTextStyle: .body)
        mailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        websiteLabel.font = UIFont.preferredFont(forTextStyle: .body)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }


}
