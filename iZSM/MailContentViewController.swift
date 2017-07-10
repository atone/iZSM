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
import SafariServices

class MailContentViewController: UIViewController, UITextViewDelegate {
    
    let titleLabel = UILabel()
    let userButton = UIButton(type: .system)
    let timeLabel = UILabel()
    let contentTextView = UITextView()
    
    var mail: SMMail?
    var inbox: Bool = true
    private let api = SmthAPI()
    private var detailMail: SMMail?
    
    func setupUI() {
        view.backgroundColor = UIColor.white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        userButton.addTarget(self, action: #selector(clickUserButton(button:)), for: .touchUpInside)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.textColor = UIColor.gray
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = [.phoneNumber, .link]
        view.addSubview(titleLabel)
        view.addSubview(userButton)
        view.addSubview(timeLabel)
        view.addSubview(contentTextView)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(5)
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
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-5)
        }
        
        if inbox {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .reply,
                                            target: self,
                                            action: #selector(reply(sender:)))
            let actionItem = UIBarButtonItem(barButtonSystemItem: .action,
                                             target: self,
                                             action: #selector(forward(sender:)))
            navigationItem.rightBarButtonItems = [actionItem, replyItem]
        } else {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .reply,
                                            target: self,
                                            action: #selector(reply(sender:)))
            navigationItem.rightBarButtonItem = replyItem
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTextView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        setupUI()
        fetchData()
    }
    
    func clickUserButton(button: UIButton) {
        if let userID = button.titleLabel?.text {
            networkActivityIndicatorStart()
            SMUserInfoUtil.querySMUser(for: userID) { (user) in
                networkActivityIndicatorStop()
                let userInfoVC = UserInfoViewController()
                userInfoVC.modalPresentationStyle = .popover
                userInfoVC.user = user
                userInfoVC.delegate = self
                let presentationCtr = userInfoVC.presentationController as! UIPopoverPresentationController
                presentationCtr.sourceView = button
                presentationCtr.delegate = self
                self.present(userInfoVC, animated: true)
            }
        }
    }
    
    func reply(sender: UIBarButtonItem) {
        if let mail = self.detailMail {
            let cevc = ComposeEmailController()
            cevc.originalEmail = mail
            cevc.replyMode = true
            let navigationController = UINavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
            
        }
    }
    
    func forward(sender: UIBarButtonItem) {
        if let originalMail = self.detailMail {
            let alert = UIAlertController(title: "转寄信件", message: nil, preferredStyle: .alert)
            alert.addTextField{ textField in
                textField.placeholder = "收件人"
                textField.autocorrectionType = .no
                textField.keyboardType = .asciiCapable
                textField.returnKeyType = .send
            }
            let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert] action in
                if let textField = alert.textFields?.first {
                    networkActivityIndicatorStart()
                    DispatchQueue.global().async {
                        let result = self.api.forwardMailAtPosition(position: originalMail.position, toUser: textField.text!)
                        print("forward mail status: \(result)")
                        DispatchQueue.main.async {
                            networkActivityIndicatorStop()
                            if self.api.errorCode == 0 {
                                SVProgressHUD.showSuccess(withStatus: "转寄成功")
                            } else if let errorDescription = self.api.errorDescription {
                                if errorDescription != "" {
                                    SVProgressHUD.showInfo(withStatus: errorDescription)
                                } else {
                                    SVProgressHUD.showError(withStatus: "出错了")
                                }
                            } else {
                                SVProgressHUD.showError(withStatus: "出错了")
                            }
                        }
                    }
                }
            }
            alert.addAction(okAction)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func preferredFontSizeChanged(notification: Notification) {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let urlString = URL.absoluteString
        print("Clicked: \(urlString)")
        if urlString.hasPrefix("http") {
            let webViewController = SFSafariViewController(url: URL)
            present(webViewController, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(URL)
        }
        return false
    }
    
    private func fetchData() {
        titleLabel.text = nil
        userButton.setTitle(nil, for: .normal)
        timeLabel.text = nil
        contentTextView.text = nil
        networkActivityIndicatorStart()
        SVProgressHUD.show()
        DispatchQueue.global().async {
            if let mail = self.mail {
                if self.inbox {
                    self.detailMail = self.api.getMailAtPosition(position: mail.position)
                } else {
                    self.detailMail = self.api.getMailSentAtPosition(position: mail.position)
                }
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                SVProgressHUD.dismiss()
                if let detailMail = self.detailMail {
                    if self.inbox {
                        self.title = "来自 \(detailMail.authorID) 的邮件"
                    } else {
                        self.title = "发给 \(detailMail.authorID) 的邮件"
                    }
                    self.titleLabel.text = detailMail.subject
                    self.userButton.setTitle(detailMail.authorID, for: .normal)
                    self.timeLabel.text = detailMail.time.shortDateString
                    self.contentTextView.attributedText = self.attributedStringFromContent(detailMail.body)
                }
            }
        }
    }
    
    private func attributedStringFromContent(_ string: String) -> NSAttributedString {
        let attributeText = NSMutableAttributedString()
        
        let normal = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body),
                      NSParagraphStyleAttributeName: NSParagraphStyle.default,
                      NSForegroundColorAttributeName: UIColor.black]
        let quoted = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body),
                      NSParagraphStyleAttributeName: NSParagraphStyle.default,
                      NSForegroundColorAttributeName: UIColor.gray]
        
        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }
    
}

extension MailContentViewController: UserInfoViewControllerDelegate {
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
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
