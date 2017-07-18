//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices
import SVProgressHUD

class AboutViewController: NTTableViewController {

    @IBOutlet weak var silverSupportLabel: UILabel!
    @IBOutlet weak var silverSupportCell: UITableViewCell!
    @IBOutlet weak var goldSupportLabel: UILabel!
    @IBOutlet weak var goldSupportCell: UITableViewCell!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var mailCell: UITableViewCell!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var websiteCell: UITableViewCell!
    
    let logoView = LogoView(frame: CGRect.zero)
    
    let iapHelper = IAPHelper()
    
    lazy var priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    private var silverSupport: SKProduct?
    private var goldSupport: SKProduct?
    
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
        
        if IAPHelper.canMakePayments() {
            silverSupportLabel.text = "我要赞赏 (加载中...)"
            goldSupportLabel.text = "我要赞赏 (加载中...)"
            iapHelper.requestProducts { [weak self] (success, products) in
                if let `self` = self {
                    if success, let products = products {
                        for prod in products {
                            if prod.productIdentifier == IAPHelper.SilverSupport {
                                self.silverSupport = prod
                                self.priceFormatter.locale = prod.priceLocale
                                if let priceString = self.priceFormatter.string(from: prod.price) {
                                    self.silverSupportLabel.text = "我要赞赏 (\(priceString))"
                                }
                            } else if prod.productIdentifier == IAPHelper.GoldSupport {
                                self.goldSupport = prod
                                self.priceFormatter.locale = prod.priceLocale
                                if let priceString = self.priceFormatter.string(from: prod.price) {
                                    self.goldSupportLabel.text = "我要赞赏 (\(priceString))"
                                }
                            }
                        }
                    } else {
                        self.silverSupportLabel.text = "我要赞赏 (请重试)"
                        self.goldSupportLabel.text = "我要赞赏 (请重试)"
                    }
                }
            }
        } else {
            silverSupportLabel.text = "我要赞赏 (不可用)"
            goldSupportLabel.text = "我要赞赏 (不可用)"
        }
    }
    

    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // handle font size change
    func preferredFontSizeChanged(notification: Notification) {
        updateUI()
    }
    
    func buySupport(support: SKProduct) {
        SVProgressHUD.show()
        iapHelper.buyProduct(support) { [weak self] (success, productId) in
            SVProgressHUD.dismiss()
            if let `self` = self {
                if !success {
                    let alert = UIAlertController(title: "赞赏失败", message: "很抱歉，未能完成购买，\n请您重新尝试。", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "好的", style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            if let silverSupport = silverSupport {
                buySupport(support: silverSupport)
            }
        case IndexPath(row: 1, section: 0):
            if let goldSupport = goldSupport {
                buySupport(support: goldSupport)
            }
        case IndexPath(row: 0, section: 1):
            let urlAddress = "https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=979484184&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
            UIApplication.shared.openURL(URL(string: urlAddress)!)
        case IndexPath(row: 1, section: 1):
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
        case IndexPath(row: 2, section: 1):
            let urlAddress = "https://www.yunaitong.cn/zsmth-released.html"
            let webViewController = SFSafariViewController(url: URL(string: urlAddress)!)
            present(webViewController, animated: true, completion: nil)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func updateUI() {
        silverSupportLabel.font = UIFont.preferredFont(forTextStyle: .body)
        silverSupportLabel.textColor = IAPHelper.canMakePayments() ? AppTheme.shared.textColor : AppTheme.shared.lightTextColor
        goldSupportLabel.font = UIFont.preferredFont(forTextStyle: .body)
        goldSupportLabel.textColor = IAPHelper.canMakePayments() ? AppTheme.shared.textColor : AppTheme.shared.lightTextColor
        rateLabel.font = UIFont.preferredFont(forTextStyle: .body)
        rateLabel.textColor = AppTheme.shared.textColor
        mailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        mailLabel.textColor = AppTheme.shared.textColor
        websiteLabel.font = UIFont.preferredFont(forTextStyle: .body)
        websiteLabel.textColor = AppTheme.shared.textColor
        
        silverSupportCell.backgroundColor = AppTheme.shared.backgroundColor
        goldSupportCell.backgroundColor = AppTheme.shared.backgroundColor
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
