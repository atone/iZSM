//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class AboutViewController: NTTableViewController {

    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var mailCell: UITableViewCell!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var websiteCell: UITableViewCell!
    
    let logoView = LogoView(frame: CGRect.zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
            selector: #selector(preferredFontSizeChanged(notification:)),
            name: .UIContentSizeCategoryDidChange,
            object: nil)
        
        let size = self.view.bounds.size
        let width = size.width < size.height ? size.width : size.height
        logoView.frame = CGRect(x: 0, y: 0, width: width, height: width * 3 / 4)
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
            let urlAddress = "https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
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
            let navigationController = NTNavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
        case IndexPath(row: 2, section: 0):
            let urlAddress = "https://www.yunaitong.cn/zsmth-released.html"
            let webViewController = SFSafariViewController(url: URL(string: urlAddress)!)
            present(webViewController, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func updateUI() {
        rateLabel.font = UIFont.preferredFont(forTextStyle: .body)
        rateLabel.textColor = AppTheme.shared.textColor
        mailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        mailLabel.textColor = AppTheme.shared.textColor
        websiteLabel.font = UIFont.preferredFont(forTextStyle: .body)
        websiteLabel.textColor = AppTheme.shared.textColor
        
        rateCell.backgroundColor = AppTheme.shared.backgroundColor
        mailCell.backgroundColor = AppTheme.shared.backgroundColor
        websiteCell.backgroundColor = AppTheme.shared.backgroundColor
        logoView.updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }


}
