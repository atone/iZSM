//
//  ComposeEmailController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit
import SVProgressHUD

class ComposeEmailController: UIViewController, UITextFieldDelegate {

    let sendToLabel = UILabel()
    let receiverTextField = UITextField()
    let titleHintLabel = UILabel()
    let titleTextField = UITextField()
    let contentTextView = UITextView()
    let countLabel = UILabel()
    var doneButton: UIBarButtonItem?
    
    var preTitle: String?
    var preContent: String?
    var preReceiver: String?
    
    var delegate: ComposeEmailControllerDelegate?
    
    var replyMode = false
    var originalEmail: SMMail?
    
    let signature = "\n- 来自「最水木 for iOS」"
    
    var emailTitle: String? {
        get { return titleTextField.text }
        set { titleTextField.text = newValue }
    }
    
    var emailContent: String? {
        get { return contentTextView.text }
        set { contentTextView.text = newValue }
    }
    
    var emailReceiver: String? {
        get { return receiverTextField.text }
        set { receiverTextField.text = newValue }
    }
    
    var keyboardHeight: Constraint?
    
    private let api = SmthAPI()
    private let setting = AppSetting.sharedSetting
    
    func setEditable(_ editable: Bool) {
        receiverTextField.isEnabled = editable
        titleTextField.isEnabled = editable
        contentTextView.isEditable = editable
    }
    
    private func setupUI() {
        let cornerRadius: CGFloat = 4
        view.backgroundColor = UIColor.white
        title = "写邮件"
        sendToLabel.text = "寄给"
        sendToLabel.font = UIFont.systemFont(ofSize: 14)
        sendToLabel.textColor = UIColor.white
        sendToLabel.backgroundColor = UIColor.lightGray
        sendToLabel.textAlignment = .center
        sendToLabel.layer.cornerRadius = cornerRadius
        sendToLabel.layer.masksToBounds = true
        titleHintLabel.text = "标题"
        titleHintLabel.font = UIFont.systemFont(ofSize: 14)
        titleHintLabel.textColor = UIColor.white
        titleHintLabel.backgroundColor = UIColor.lightGray
        titleHintLabel.textAlignment = .center
        titleHintLabel.layer.cornerRadius = cornerRadius
        titleHintLabel.layer.masksToBounds = true
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(change(textField:)), for: .editingChanged)
        titleTextField.setContentHuggingPriority(countLabel.contentHuggingPriority(for: .horizontal) - 1, for: .horizontal)
        titleTextField.setContentCompressionResistancePriority(countLabel.contentCompressionResistancePriority(for: .horizontal) - 1, for: .horizontal)
        titleTextField.textColor = UIColor.lightGray
        titleTextField.font = UIFont.systemFont(ofSize: 16)
        titleTextField.placeholder = "添加标题"
        titleTextField.autocapitalizationType = .none
        titleTextField.returnKeyType = .next
        receiverTextField.delegate = self
        receiverTextField.addTarget(self, action: #selector(change(textField:)), for: .editingChanged)
        receiverTextField.setContentHuggingPriority(sendToLabel.contentHuggingPriority(for: .horizontal) - 1, for: .horizontal)
        receiverTextField.setContentCompressionResistancePriority(sendToLabel.contentCompressionResistancePriority(for: .horizontal) - 1, for: .horizontal)
        receiverTextField.textColor = UIColor.lightGray
        receiverTextField.font = UIFont.systemFont(ofSize: 16)
        receiverTextField.placeholder = "收信人"
        receiverTextField.autocapitalizationType = .none
        receiverTextField.returnKeyType = .next
        contentTextView.setContentHuggingPriority(titleHintLabel.contentHuggingPriority(for: .vertical) - 1, for: .vertical)
        contentTextView.setContentCompressionResistancePriority(titleHintLabel.contentCompressionResistancePriority(for: .vertical) - 1, for: .vertical)
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
        contentTextView.autocapitalizationType = .sentences
        contentTextView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        contentTextView.layer.cornerRadius = cornerRadius
        contentTextView.layer.masksToBounds = true
        countLabel.text = "0"
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.textColor = UIColor.lightGray
        
        doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                     target: self,
                                     action: #selector(done(sender:)))
        doneButton?.isEnabled = false
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancel(sender:)))
        
        view.addSubview(sendToLabel)
        view.addSubview(receiverTextField)
        view.addSubview(titleHintLabel)
        view.addSubview(titleTextField)
        view.addSubview(countLabel)
        view.addSubview(contentTextView)
        
        sendToLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(5)
            make.width.equalTo(38)
            make.height.equalTo(20)
        }
        
        receiverTextField.snp.makeConstraints { (make) in
            make.height.equalTo(sendToLabel.snp.height)
            make.leading.equalTo(sendToLabel.snp.trailing).offset(5)
            make.lastBaseline.equalTo(sendToLabel.snp.lastBaseline)
            make.trailing.equalTo(view.snp.trailingMargin)
        }
        
        titleHintLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(sendToLabel)
            make.top.equalTo(sendToLabel.snp.bottom).offset(5)
            make.width.equalTo(38)
            make.height.equalTo(20)
        }
        titleTextField.snp.makeConstraints { (make) in
            make.height.equalTo(titleHintLabel.snp.height)
            make.leading.equalTo(titleHintLabel.snp.trailing).offset(5)
            make.lastBaseline.equalTo(titleHintLabel.snp.lastBaseline)
        }
        countLabel.snp.makeConstraints { (make) in
            make.height.equalTo(titleTextField.snp.height)
            make.lastBaseline.equalTo(titleTextField.snp.lastBaseline)
            make.trailing.equalTo(receiverTextField.snp.trailing)
            make.leading.equalTo(titleTextField.snp.trailing).offset(5)
        }
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleHintLabel)
            make.trailing.equalTo(countLabel)
            self.keyboardHeight = make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-5).constraint
            make.top.equalTo(countLabel.snp.bottom).offset(5)
        }
        
        if replyMode {
            handleReplyMode()
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        } else {
            emailTitle = preTitle
            emailContent = preContent
            emailReceiver = preReceiver
            if let emailTitle = emailTitle {
                countLabel.text = "\((emailTitle).characters.count)"
            }
            
            if emailReceiver == nil || emailReceiver!.characters.count == 0 {
                receiverTextField.becomeFirstResponder()
            } else if emailTitle == nil || emailTitle!.characters.count == 0 {
                titleTextField.becomeFirstResponder()
            } else {
                contentTextView.becomeFirstResponder()
                contentTextView.selectedRange = NSMakeRange(0, 0)
            }
        }
    }
    
    func cancel(sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func done(sender: UIBarButtonItem) {
        networkActivityIndicatorStart()
        SVProgressHUD.show()
        setEditable(false)
        DispatchQueue.global().async {
            var content = self.emailContent!
            if content.hasSuffix("\n") {
                content = content + self.signature
            } else {
                content = content + "\n" + self.signature
            }
            let result = self.api.sendMailTo(user: self.emailReceiver!, withTitle: self.emailTitle!, content: content)
            print("send mail status: \(result)")
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                SVProgressHUD.dismiss()
                if self.api.errorCode == 0 {
                    if self.replyMode {
                        SVProgressHUD.showSuccess(withStatus: "回信成功")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "寄信成功")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.delegate?.emailDidPosted()
                        self.presentingViewController?.dismiss(animated: true, completion: nil)
                    }
                } else if let errorDescription = self.api.errorDescription {
                    if errorDescription != "" {
                        SVProgressHUD.showInfo(withStatus: errorDescription)
                    } else {
                        SVProgressHUD.showError(withStatus: "出错了")
                    }
                    self.setEditable(true)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                    self.setEditable(true)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(notification:)),
                                               name: .UIKeyboardWillChangeFrame,
                                               object: nil)
        setupUI()
    }
    
    func handleReplyMode() {
        title = "回复邮件"
        doneButton?.isEnabled = true
        if let email = originalEmail {
            // 处理标题
            if email.subject.lowercased().hasPrefix("re: ") {
                emailTitle = email.subject
            } else {
                emailTitle = "Re: " + email.subject
            }
            emailReceiver = email.authorID
            countLabel.text = "\((emailTitle!).characters.count)"
            // 处理内容
            var tempContent = "\n【 在 \(email.authorID) 的来信中提到: 】\n"
            var origContent = email.body + "\n"
            
            if let range = origContent.range(of: signature) {
                origContent.replaceSubrange(range, with: "")
            }
            
            for _ in 1...3 {
                if let linebreak = origContent.range(of: "\n") {
                    tempContent += (": " + origContent.substring(to: linebreak.upperBound))
                    origContent = origContent.substring(from: linebreak.upperBound)
                } else {
                    break
                }
            }
            if origContent.range(of: "\n") != nil {
                tempContent += ": ....................\n"
            }
            emailContent = tempContent
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: Notification) {
        let info = notification.userInfo
        let animationDuration = (info?[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        var keyboardFrame = (info?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = view.convert(keyboardFrame, from: view.window)
        let height = keyboardFrame.size.height
        keyboardHeight?.update(offset: -height - 5)
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === receiverTextField {
            titleTextField.becomeFirstResponder()
        } else {
            contentTextView.becomeFirstResponder()
        }
        return false
    }
    
    func change(textField: UITextField) {
        if textField === titleTextField {
            countLabel.text = "\(textField.text!.characters.count)"
        }
        let userLength = receiverTextField.text!.characters.count
        let titleLength = titleTextField.text!.characters.count
        if userLength > 0 && titleLength > 0 {
            doneButton?.isEnabled = true
        } else {
            doneButton?.isEnabled = false
        }
    }

}

protocol ComposeEmailControllerDelegate {
    func emailDidPosted()
}
