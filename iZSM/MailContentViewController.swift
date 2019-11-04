//
//  MailContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit
import SVProgressHUD
import SmthConnection

class MailContentViewController: UIViewController, UITextViewDelegate {
    let setting = AppSetting.shared
    let titleLabel = UILabel()
    let userButton = UIButton(type: .system)
    let timeLabel = UILabel()
    let contentTextView = UITextView()
    
    var mail: SMMail?
    var inbox: Bool = true
    private let api = SmthAPI.shared
    private var detailMail: Mail?
    
    func setupUI() {
        let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let otherDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        let bodyDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        titleLabel.numberOfLines = 0
        userButton.titleLabel?.font = UIFont.systemFont(ofSize: otherDescr.pointSize * setting.fontScale)
        userButton.addTarget(self, action: #selector(clickUserButton(_:)), for: .touchUpInside)
        timeLabel.font = UIFont.systemFont(ofSize: otherDescr.pointSize * setting.fontScale)
        contentTextView.font = UIFont.systemFont(ofSize: bodyDescr.pointSize * setting.fontScale)
        contentTextView.alwaysBounceVertical = true
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = [.phoneNumber, .link]
        view.addSubview(titleLabel)
        view.addSubview(userButton)
        view.addSubview(timeLabel)
        view.addSubview(contentTextView)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(5)
            make.trailing.equalTo(view.snp.trailingMargin)
        }
        userButton.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(titleLabel)
            make.centerY.equalTo(userButton)
        }
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(userButton.snp.bottom).offset(5)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-5)
        }
        
        if inbox {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .reply,
                                            target: self,
                                            action: #selector(reply(_:)))
            let actionItem = UIBarButtonItem(barButtonSystemItem: .action,
                                             target: self,
                                             action: #selector(forward(_:)))
            navigationItem.rightBarButtonItems = [actionItem, replyItem]
        } else {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .reply,
                                            target: self,
                                            action: #selector(reply(_:)))
            navigationItem.rightBarButtonItem = replyItem
        }
        updateColor()
    }
    
    private func updateColor() {
        view.backgroundColor = UIColor.systemBackground
        view.tintColor = UIColor(named: "SmthColor")
        titleLabel.textColor = UIColor(named: "MainText")
        userButton.tintColor = UIColor(named: "SmthColor")
        timeLabel.textColor = UIColor.secondaryLabel
        contentTextView.backgroundColor = UIColor.clear
        if let body = detailMail?.body {
            contentTextView.attributedText = attributedStringFromContent(body)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTextView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: SettingsViewController.fontScaleDidChangeNotification,
                                               object: nil)
        setupUI()
        fetchData()
    }
    
    @objc private func clickUserButton(_ button: UIButton) {
        if let userID = button.titleLabel?.text {
            networkActivityIndicatorStart()
            SMUserInfo.querySMUser(for: userID) { (user) in
                networkActivityIndicatorStop()
                let userInfoVC = UserInfoViewController()
                userInfoVC.modalPresentationStyle = .popover
                userInfoVC.user = user
                userInfoVC.delegate = self
                let presentationCtr = userInfoVC.presentationController as! UIPopoverPresentationController
                presentationCtr.sourceView = button
                presentationCtr.sourceRect = button.bounds
                presentationCtr.delegate = self
                self.present(userInfoVC, animated: true)
            }
        }
    }
    
    @objc private func reply(_ sender: UIBarButtonItem) {
        if let mail = self.detailMail {
            let cevc = ComposeEmailController()
            cevc.email = mail
            cevc.mode = .reply
            let navigationController = NTNavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
            
        }
    }
    
    @objc private func forward(_ sender: UIBarButtonItem) {
        if let originalMail = self.detailMail {
            let alert = UIAlertController(title: "转寄信件", message: nil, preferredStyle: .alert)
            alert.addTextField{ textField in
                textField.placeholder = "收件人"
                textField.autocorrectionType = .no
                textField.keyboardType = .asciiCapable
                textField.returnKeyType = .send
            }
            let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert] _ in
                guard let textField = alert.textFields?.first else { return }
                guard let receiver = textField.text else { return }
                
                networkActivityIndicatorStart()
                self.api.forwardMail(at: originalMail.position, toUser: receiver) { (result) in
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop()
                        switch result {
                        case .success:
                            SVProgressHUD.showSuccess(withStatus: "转寄成功")
                        case .failure(let error):
                            error.display()
                        }
                    }
                }
            }
            alert.addAction(okAction)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        }
    }
    
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
        let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        let otherDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        let bodyDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        userButton.titleLabel?.font = UIFont.systemFont(ofSize: otherDescr.pointSize * setting.fontScale)
        timeLabel.font = UIFont.systemFont(ofSize: otherDescr.pointSize * setting.fontScale)
        contentTextView.font = UIFont.systemFont(ofSize: bodyDescr.pointSize * setting.fontScale)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let urlString = URL.absoluteString
        dPrint("Clicked: \(urlString)")
        if urlString.hasPrefix("http") {
            let webViewController = NTSafariViewController(url: URL)
            present(webViewController, animated: true)
        } else {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        }
        return false
    }
    
    private func fetchData() {
        titleLabel.text = nil
        userButton.setTitle(nil, for: .normal)
        timeLabel.text = nil
        contentTextView.text = nil
        
        let completion: SmthCompletion<SMMail> = { (result) in
            let newResult = result.map({ Mail(from: $0) })
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                switch newResult {
                case .success(let mail):
                    self.detailMail = mail
                    if self.inbox {
                        self.title = "来自 \(mail.authorID) 的邮件"
                    } else {
                        self.title = "发给 \(mail.authorID) 的邮件"
                    }
                    self.titleLabel.text = mail.subject
                    self.userButton.setTitle(mail.authorID, for: .normal)
                    self.timeLabel.text = mail.time.shortDateString
                    self.contentTextView.attributedText = self.attributedStringFromContent(mail.body)
                case .failure(let error):
                    error.display()
                }
            }
        }
        
        networkActivityIndicatorStart(withHUD: true)
        guard let mail = self.mail else { return }
        if inbox {
            api.getMail(at: mail.position, completion: completion)
        } else {
            api.getMailSent(at: mail.position, completion: completion)
        }
    }
    
    private func attributedStringFromContent(_ string: String) -> NSAttributedString {
        let bodyDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let bodyFont = UIFont.systemFont(ofSize: bodyDescr.pointSize * setting.fontScale)
        let attributeText = NSMutableAttributedString()
        
        let normal: [NSAttributedString.Key: Any] = [.font: bodyFont,
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: UIColor(named: "MainText")!]
        let quoted: [NSAttributedString.Key: Any] = [.font: bodyFont,
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: UIColor.secondaryLabel]
        
        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(":") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }
    
}

extension MailContentViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        
    }

    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {

    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem) {

    }
    
    func shouldEnableCompose() -> Bool {
        return false
    }
    
    func shouldEnableSearch() -> Bool {
        return false
    }
}

extension MailContentViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension MailContentViewController: SmthContent {}
