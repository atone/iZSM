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
import SmthConnection

class ComposeEmailController: UIViewController, UITextFieldDelegate {
    
    enum Mode {
        case post
        case reply
        case feedback
    }
    
    private let margin: CGFloat = 8
    private let cornerRadius: CGFloat = 4

    private let sendToLabel = NTLabel()
    private let receiverTextField = UITextField()
    private let titleHintLabel = NTLabel()
    private let titleTextField = UITextField()
    private let contentTextView = UITextView()
    private let countLabel = UILabel()
    private lazy var doneButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }()
    private lazy var cancelButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
    }()
    
    var completionHandler: (() -> Void)?
    
    var email: Mail?
    var mode: Mode = .post
    
    private let signature = AppSetting.shared.signature
    private let addDeviceSignature = AppSetting.shared.addDeviceSignature
    
    private var emailTitle: String? {
        get { return titleTextField.text }
        set { titleTextField.text = newValue }
    }
    
    private var emailContent: String? {
        get { return contentTextView.text }
        set { contentTextView.text = newValue }
    }
    
    private var emailReceiver: String? {
        get { return receiverTextField.text }
        set { receiverTextField.text = newValue }
    }
    
    private var keyboardHeight: Constraint?
    
    private let api = SmthAPI.shared
    private let setting = AppSetting.shared
    
    private func setEditable(_ editable: Bool) {
        doneButton.isEnabled = editable
        cancelButton.isEnabled = editable
        receiverTextField.isEnabled = editable
        titleTextField.isEnabled = editable
        contentTextView.isEditable = editable
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        sendToLabel.text = "寄给"
        sendToLabel.font = .preferredFont(forTextStyle: .subheadline)
        sendToLabel.textAlignment = .center
        sendToLabel.textColor = .systemBackground
        sendToLabel.backgroundColor = .secondaryLabel
        let m = cornerRadius / 2
        sendToLabel.contentInsets = UIEdgeInsets(top: m, left: m, bottom: m, right: m)
        sendToLabel.lineBreakMode = .byClipping
        sendToLabel.layer.cornerRadius = cornerRadius
        sendToLabel.layer.masksToBounds = true
        sendToLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        sendToLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleHintLabel.text = "标题"
        titleHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleHintLabel.textAlignment = .center
        titleHintLabel.textColor = .systemBackground
        titleHintLabel.backgroundColor = .secondaryLabel
        titleHintLabel.contentInsets = UIEdgeInsets(top: m, left: m, bottom: m, right: m)
        titleHintLabel.lineBreakMode = .byClipping
        titleHintLabel.layer.cornerRadius = cornerRadius
        titleHintLabel.layer.masksToBounds = true
        titleHintLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleHintLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        titleTextField.font = .preferredFont(forTextStyle: .body)
        titleTextField.textColor = .secondaryLabel
        titleTextField.placeholder = "添加标题"
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(changeDoneButton(_:)), for: .editingChanged)
        titleTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleTextField.autocapitalizationType = .none
        titleTextField.returnKeyType = .next
        receiverTextField.font = .preferredFont(forTextStyle: .body)
        receiverTextField.textColor = .secondaryLabel
        receiverTextField.placeholder = "收信人"
        receiverTextField.delegate = self
        receiverTextField.addTarget(self, action: #selector(changeDoneButton(_:)), for: .editingChanged)
        receiverTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        receiverTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        receiverTextField.autocapitalizationType = .none
        receiverTextField.returnKeyType = .next
        contentTextView.setContentHuggingPriority(.defaultLow, for: .vertical)
        contentTextView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        contentTextView.font = .systemFont(ofSize: descriptor.pointSize * setting.fontScale)
        contentTextView.autocapitalizationType = .sentences
        contentTextView.backgroundColor = .systemGroupedBackground
        contentTextView.textColor = UIColor(named: "MainText")
        contentTextView.layer.cornerRadius = cornerRadius
        contentTextView.layer.masksToBounds = true
        countLabel.text = "0"
        countLabel.font = .preferredFont(forTextStyle: .body)
        countLabel.textColor = .secondaryLabel
        countLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        doneButton.isEnabled = false
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubview(sendToLabel)
        view.addSubview(receiverTextField)
        view.addSubview(titleHintLabel)
        view.addSubview(titleTextField)
        view.addSubview(countLabel)
        view.addSubview(contentTextView)
        
        sendToLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(margin)
        }
        
        receiverTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(sendToLabel.snp.trailing).offset(margin)
            make.lastBaseline.equalTo(sendToLabel)
            make.trailing.equalTo(view.snp.trailingMargin)
        }
        
        titleHintLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(sendToLabel)
            make.top.equalTo(sendToLabel.snp.bottom).offset(margin)
        }
        titleTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(titleHintLabel.snp.trailing).offset(margin)
            make.lastBaseline.equalTo(titleHintLabel)
        }
        countLabel.snp.makeConstraints { (make) in
            make.lastBaseline.equalTo(titleTextField)
            make.trailing.equalTo(receiverTextField)
            make.leading.equalTo(titleTextField.snp.trailing).offset(margin)
        }
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleHintLabel)
            make.trailing.equalTo(countLabel)
            self.keyboardHeight = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-margin).constraint
            make.top.equalTo(countLabel.snp.bottom).offset(margin)
        }
    }
    
    private func setupMode() {
        switch mode {
        case .post:
            title = "撰写邮件"
            doneButton.isEnabled = false
            if let email = email {
                emailTitle = email.subject
                emailContent = email.body
                emailReceiver = email.authorID
            }
            if emailReceiver == nil || emailReceiver!.count == 0 {
                receiverTextField.becomeFirstResponder()
            } else if emailTitle == nil || emailTitle!.count == 0 {
                titleTextField.becomeFirstResponder()
            } else {
                doneButton.isEnabled = true
                contentTextView.becomeFirstResponder()
                contentTextView.selectedRange = NSMakeRange(0, 0)
            }
            countLabel.text = "\(emailTitle?.count ?? 0)"
        case .reply:
            title = "回复邮件"
            if let email = email {
                emailTitle = email.replySubject
                emailContent = email.quotBody
                emailReceiver = email.authorID
            }
            doneButton.isEnabled = true
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
            countLabel.text = "\(emailTitle?.count ?? 0)"
        case .feedback:
            title = "邮件反馈"
            doneButton.isEnabled = false
            if let email = email {
                emailTitle = email.subject
                emailContent = email.body
                emailReceiver = email.authorID
            }
            if emailReceiver == nil || emailReceiver!.count == 0 {
                receiverTextField.becomeFirstResponder()
            } else if emailTitle == nil || emailTitle!.count == 0 {
                titleTextField.becomeFirstResponder()
            } else {
                doneButton.isEnabled = true
                contentTextView.becomeFirstResponder()
                contentTextView.selectedRange = NSMakeRange(0, 0)
            }
            countLabel.text = "\(emailTitle?.count ?? 0)"
        }
    }
    
    @objc private func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @objc private func done(_ sender: Any) {
        if let receiver = self.emailReceiver, let title = self.emailTitle, var content = self.emailContent {
            networkActivityIndicatorStart(withHUD: true)
            setEditable(false)
            let lines = content.components(separatedBy: .newlines).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            content = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if addDeviceSignature {
                content.append("\n\n" + self.signature)
            }
            api.sendMail(to: receiver, title: title, content: content) { (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        dPrint("send mail done.")
                        switch self.mode {
                        case .post:
                            SVProgressHUD.showSuccess(withStatus: "寄信成功")
                        case .reply:
                            SVProgressHUD.showSuccess(withStatus: "回信成功")
                        case .feedback:
                            SVProgressHUD.showSuccess(withStatus: "感谢反馈")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.completionHandler?()
                            self.dismiss(animated: true)
                        }
                    case .failure(let error):
                        error.display()
                        self.setEditable(true)
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        setupUI()
        setupMode()
        setupKeyCommand()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo
        let animationDuration = info?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        var keyboardFrame = info?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        keyboardFrame = view.convert(keyboardFrame, from: view.window)
        let height = max(view.bounds.height - view.safeAreaInsets.bottom - keyboardFrame.origin.y, 0)
        keyboardHeight?.update(offset: -height - margin)
        UIView.animate(withDuration: animationDuration) {
            self.view.layoutIfNeeded()
        }
        
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
    
    @objc private func changeDoneButton(_ textField: UITextField) {
        if textField === titleTextField {
            countLabel.text = "\(textField.text!.count)"
        }
        let userLength = receiverTextField.text!.count
        let titleLength = titleTextField.text!.count
        if userLength > 0 && titleLength > 0 {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
    }
}

extension ComposeEmailController {
    func setupKeyCommand() {
        let doneKeyCommand = UIKeyCommand(title: "寄出", action: #selector(done(_:)), input: "\r", modifierFlags: [.command])
        let cancelKeyCommand = UIKeyCommand(title: "取消", action: #selector(cancel(_:)), input: UIKeyCommand.inputEscape)
        addKeyCommand(doneKeyCommand)
        addKeyCommand(cancelKeyCommand)
    }
}
