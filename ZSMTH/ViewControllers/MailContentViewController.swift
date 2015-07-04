//
//  MailContentViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/20.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import RSTWebViewController

class MailContentViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView! {
        didSet {
            contentTextView.delegate = self
        }
    }

    var mail: SMMail?
    var inbox: Bool = true
    private let api = SmthAPI()
    private var detailMail: SMMail?

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "preferredFontSizeChanged:",
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
        if inbox {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: "reply:")
            let actionItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "forward:")
            navigationItem.rightBarButtonItems = [actionItem, replyItem]
        } else {
            let replyItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: "reply:")
            navigationItem.rightBarButtonItem = replyItem
        }
        fetchData()
    }

    func reply(sender: UIBarButtonItem) {
        if let mail = self.detailMail {
            let cevc = storyboard?.instantiateViewControllerWithIdentifier("ComposeEmailController") as! ComposeEmailController
            cevc.originalEmail = mail
            cevc.replyMode = true
            cevc.modalPresentationStyle = .FormSheet
            let navigationController = UINavigationController(rootViewController: cevc)
            presentViewController(navigationController, animated: true, completion: nil)

        }
    }

    func forward(sender: UIBarButtonItem) {
        if let originalMail = self.detailMail {
            let alert = UIAlertController(title: "转寄信件", message: nil, preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler{ textField in
                textField.placeholder = "收件人"
            }
            let okAction = UIAlertAction(title: "确定", style: .Default) { [unowned alert] action in
                if let textField = alert.textFields?.first as? UITextField {
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    networkActivityIndicatorStart()
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        self.api.forwardMailAtPosition(originalMail.position, toUser: textField.text)
                        dispatch_async(dispatch_get_main_queue()) {
                            networkActivityIndicatorStop()
                            hud.mode = .Text
                            if self.api.errorCode == 0 {
                                hud.labelText = "转寄成功"
                            } else if let errorDescription = self.api.errorDescription {
                                if errorDescription != "" {
                                    hud.labelText = errorDescription
                                } else {
                                    hud.labelText = "出错了"
                                }
                            } else {
                                hud.labelText = "出错了"
                            }
                            hud.hide(true, afterDelay: 1)
                        }
                    }
                }
            }
            alert.addAction(okAction)
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }

    func preferredFontSizeChanged(notification: NSNotification) {
        titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        userButton?.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        timeLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        contentTextView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
    }

    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        let webViewController = RSTWebViewController(URL: URL)
        webViewController.showsDoneButton = true
        let navigationController = NYNavigationController(rootViewController: webViewController)
        presentViewController(navigationController, animated: true, completion: nil)

        return false
    }

    private func fetchData() {
        titleLabel?.text = nil
        userButton?.setTitle(nil, forState: .Normal)
        timeLabel?.text = nil
        contentTextView?.text = nil
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let mail = self.mail {
                if self.inbox {
                    self.detailMail = self.api.getMailAtPosition(mail.position)
                } else {
                    self.detailMail = self.api.getMailSentAtPosition(mail.position)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                hud.hide(true)
                networkActivityIndicatorStop()
                if let detailMail = self.detailMail {
                    if self.inbox {
                        self.title = "来自 \(detailMail.authorID) 的邮件"
                    } else {
                        self.title = "发给 \(detailMail.authorID) 的邮件"
                    }
                    self.titleLabel?.text = detailMail.subject
                    self.userButton?.setTitle(detailMail.authorID, forState: .Normal)
                    self.timeLabel?.text = self.stringFromDate(detailMail.time)
                    self.contentTextView?.attributedText = self.attributedStringFromContentString(detailMail.body)
                }
            }
        }
    }

    private func attributedStringFromContentString(string: String) -> NSAttributedString {
        var attributeText = NSMutableAttributedString()

        let normal = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSParagraphStyleAttributeName: NSParagraphStyle.defaultParagraphStyle(),
            NSForegroundColorAttributeName: UIColor.blackColor()]
        let quoted = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody),
            NSParagraphStyleAttributeName: NSParagraphStyle.defaultParagraphStyle(),
            NSForegroundColorAttributeName: UIColor.grayColor()]

        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.appendAttributedString(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }

    private func stringFromDate(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter.stringFromDate(date)
    }

}
