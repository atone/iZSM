//
//  ComposeEmailController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/21.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ComposeEmailController: UIViewController, UITextFieldDelegate {

    var delegate: ComposeEmailControllerDelegate?

    var replyMode = false
    var originalEmail: SMMail?

    let signature = "\n- 来自最水木 -"

    var emailTitle: String? {
        get { return titleTextField?.text }
        set { titleTextField?.text = newValue }
    }

    var emailContent: String? {
        get { return contentTextView?.text }
        set { contentTextView?.text = newValue }
    }

    var emailReceiver: String? {
        get { return receiverTextField?.text }
        set { receiverTextField?.text = newValue }
    }
    

    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var sendToLabel: UILabel! {
        didSet { sendToLabel?.layer.cornerRadius = 2 }
    }
    @IBOutlet weak var titleLabel: UILabel! {
        didSet { titleLabel?.layer.cornerRadius = 2 }
    }

    @IBOutlet weak var receiverTextField: UITextField! {
        didSet {
            receiverTextField?.delegate = self
            receiverTextField?.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        }
    }
    @IBOutlet weak var titleTextField: UITextField! {
        didSet {
            titleTextField?.delegate = self
            titleTextField?.addTarget(self, action: "textFieldDidChange:", forControlEvents: .EditingChanged)

        }
    }
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var keyboardHeight: NSLayoutConstraint!

    private let api = SmthAPI()
    private let setting = AppSetting.sharedSetting

    

    @IBAction func cancel(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func done(sender: UIBarButtonItem) {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var content = self.emailContent!
            if content.hasSuffix("\n") {
                content = content + self.signature
            } else {
                content = content + "\n" + self.signature
            }
            self.api.sendMailTo(self.emailReceiver!, withTitle: self.emailTitle!, content: content)
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                hud.mode = .Text
                if self.api.errorCode == 0 {
                    if self.replyMode {
                        hud.labelText = "回信成功"
                    } else {
                        hud.labelText = "寄信成功"
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.delegate?.emailDidPosted()
                        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                    }
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

    override func viewDidLoad() {
        UIApplication.sharedApplication().setStatusBarStyle(.Default, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        if replyMode {
            handleReplyMode()
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        } else {
            receiverTextField.becomeFirstResponder()
        }
    }

    func handleReplyMode() {
        navigationBar?.topItem?.title = "回复邮件"
        doneButton.enabled = true
        if let email = originalEmail {
            // 处理标题
            if email.subject.lowercaseString.hasPrefix("re: ") {
                emailTitle = email.subject
            } else {
                emailTitle = "Re: " + email.subject
            }
            emailReceiver = email.authorID
            countLabel.text = "\(count(emailTitle!))"
            // 处理内容
            var tempContent = "\n【 在 \(email.authorID) 的来信中提到: 】\n"
            var origContent = email.body + "\n"

            if let range = origContent.rangeOfString(signature) {
                origContent.replaceRange(range, with: "")
            }

            for i in 1...3 {
                if let linebreak = origContent.rangeOfString("\n") {
                    tempContent += (": " + origContent.substringToIndex(linebreak.endIndex))
                    origContent = origContent.substringFromIndex(linebreak.endIndex)
                } else {
                    break
                }
            }
            if let linebreak = origContent.rangeOfString("\n") {
                tempContent += ": ....................\n"
            }
            emailContent = tempContent
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: true)
    }

    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let animationDuration = (info?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        var keyboardFrame = (info?[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        keyboardFrame = view.convertRect(keyboardFrame, fromView: view.window)
        let height = keyboardFrame.size.height

        keyboardHeight.constant = height + 5

        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
    }

    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === receiverTextField {
            titleTextField.becomeFirstResponder()
        } else {
            contentTextView.becomeFirstResponder()
        }
        return false
    }

    func textFieldDidChange(textField: UITextField) {
        if textField === titleTextField {
            countLabel?.text = "\(count(textField.text))"
        }
        let userLength = count(receiverTextField.text)
        let titleLength = count(titleTextField.text)
        if userLength > 0 && titleLength > 0 {
            doneButton.enabled = true
        } else {
            doneButton.enabled = false
        }
    }

}

protocol ComposeEmailControllerDelegate {
    func emailDidPosted()
}