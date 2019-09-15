//
//  AboutViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/6/29.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import StoreKit
import SVProgressHUD
import DeviceKit

class AboutViewController: NTTableViewController {

    @IBOutlet weak var silverSupportLabel: UILabel!
    @IBOutlet weak var silverSupportCell: UITableViewCell! {
        didSet {
            if let cell = silverSupportCell {
                let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
                selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.selectedBackgroundView = selectedBackgroundView
            }
        }
    }
    @IBOutlet weak var goldSupportLabel: UILabel!
    @IBOutlet weak var goldSupportCell: UITableViewCell! {
        didSet {
            if let cell = goldSupportCell {
                let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
                selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.selectedBackgroundView = selectedBackgroundView
            }
        }
    }
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var rateCell: UITableViewCell! {
        didSet {
            if let cell = rateCell {
                let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
                selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.selectedBackgroundView = selectedBackgroundView
            }
        }
    }
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var mailCell: UITableViewCell! {
        didSet {
            if let cell = mailCell {
                let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
                selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.selectedBackgroundView = selectedBackgroundView
            }
        }
    }
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var websiteCell: UITableViewCell! {
        didSet {
            if let cell = websiteCell {
                let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
                selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.selectedBackgroundView = selectedBackgroundView
            }
        }
    }
    
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
            selector: #selector(preferredFontSizeChanged(_:)),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil)
        
        let size = self.view.bounds.size
        let smallWidth = size.width < size.height ? size.width : size.height
        logoView.frame = CGRect(x: 0, y: 0, width: size.width, height: smallWidth * 2 / 3)
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
                                    DispatchQueue.main.async {
                                        self.silverSupportLabel.text = "我要赞赏 (\(priceString))"
                                    }
                                }
                            } else if prod.productIdentifier == IAPHelper.GoldSupport {
                                self.goldSupport = prod
                                self.priceFormatter.locale = prod.priceLocale
                                if let priceString = self.priceFormatter.string(from: prod.price) {
                                    DispatchQueue.main.async {
                                        self.goldSupportLabel.text = "我要赞赏 (\(priceString))"
                                    }
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.silverSupportLabel.text = "我要赞赏 (请重试)"
                            self.goldSupportLabel.text = "我要赞赏 (请重试)"
                        }
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
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
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
                    self.present(alert, animated: true)
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
            UIApplication.shared.open(URL(string: urlAddress)!, options: [:], completionHandler: nil)
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

            let title = "「\(versionText)」应用问题反馈"
            let receiver = "atone"
            let content = "\n\n设备类型: \(Device())\n系统版本: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n应用版本: \(versionText)"
            cevc.email = SMMail(subject: title, body: content, authorID: receiver, position: 0, time: Date(), flags: "", attachments: [])
            cevc.mode = .feedback
            let navigationController = NTNavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        case IndexPath(row: 2, section: 1):
            let urlAddress = "https://www.yunaitong.cn/zsmth-released.html"
            let webViewController = NTSafariViewController(url: URL(string: urlAddress)!)
            present(webViewController, animated: true)
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func updateUI() {
        silverSupportLabel.font = UIFont.preferredFont(forTextStyle: .body)
        silverSupportLabel.textColor = IAPHelper.canMakePayments() ? UIColor.label : UIColor.secondaryLabel
        goldSupportLabel.font = UIFont.preferredFont(forTextStyle: .body)
        goldSupportLabel.textColor = IAPHelper.canMakePayments() ? UIColor.label : UIColor.secondaryLabel
        rateLabel.font = UIFont.preferredFont(forTextStyle: .body)
        rateLabel.textColor = UIColor.label
        mailLabel.font = UIFont.preferredFont(forTextStyle: .body)
        mailLabel.textColor = UIColor.label
        websiteLabel.font = UIFont.preferredFont(forTextStyle: .body)
        websiteLabel.textColor = UIColor.label
        logoView.updateUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI()
    }


}
