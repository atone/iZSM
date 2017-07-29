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
    
    enum Mode {
        case post
        case reply
        case feedback
    }

    private let sendToLabel = UILabel()
    private let receiverTextField = UITextField()
    private let titleHintLabel = UILabel()
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
    
    var email: SMMail?
    var mode: Mode = .post
    
    private let signature = AppSetting.shared.signature
    private let regx = AppSetting.shared.signatureRegularExpression
    
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
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    
    private func setEditable(_ editable: Bool) {
        doneButton.isEnabled = editable
        cancelButton.isEnabled = editable
        receiverTextField.isEnabled = editable
        titleTextField.isEnabled = editable
        contentTextView.isEditable = editable
    }
    
    private func setupUI() {
        let cornerRadius: CGFloat = 4
        sendToLabel.text = "寄给"
        sendToLabel.font = UIFont.systemFont(ofSize: 14)
        sendToLabel.textAlignment = .center
        sendToLabel.layer.cornerRadius = cornerRadius
        sendToLabel.layer.masksToBounds = true
        sendToLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        sendToLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        titleHintLabel.text = "标题"
        titleHintLabel.font = UIFont.systemFont(ofSize: 14)
        titleHintLabel.textAlignment = .center
        titleHintLabel.layer.cornerRadius = cornerRadius
        titleHintLabel.layer.masksToBounds = true
        titleHintLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        titleHintLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        titleTextField.delegate = self
        titleTextField.addTarget(self, action: #selector(changeDoneButton(_:)), for: .editingChanged)
        titleTextField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        titleTextField.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        titleTextField.font = UIFont.systemFont(ofSize: 16)
        titleTextField.autocapitalizationType = .none
        titleTextField.returnKeyType = .next
        receiverTextField.delegate = self
        receiverTextField.addTarget(self, action: #selector(changeDoneButton(_:)), for: .editingChanged)
        receiverTextField.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        receiverTextField.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
        receiverTextField.font = UIFont.systemFont(ofSize: 16)
        receiverTextField.autocapitalizationType = .none
        receiverTextField.returnKeyType = .next
        contentTextView.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .vertical)
        contentTextView.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .vertical)
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
        contentTextView.autocapitalizationType = .sentences
        contentTextView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
        contentTextView.layer.cornerRadius = cornerRadius
        contentTextView.layer.masksToBounds = true
        countLabel.text = "0"
        countLabel.font = UIFont.systemFont(ofSize: 16)
        countLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        
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
        updateColor()
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
            if emailReceiver == nil || emailReceiver!.characters.count == 0 {
                receiverTextField.becomeFirstResponder()
            } else if emailTitle == nil || emailTitle!.characters.count == 0 {
                titleTextField.becomeFirstResponder()
            } else {
                doneButton.isEnabled = true
                contentTextView.becomeFirstResponder()
                contentTextView.selectedRange = NSMakeRange(0, 0)
            }
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
        case .feedback:
            title = "邮件反馈"
            doneButton.isEnabled = false
            if let email = email {
                emailTitle = email.subject
                emailContent = email.body
                emailReceiver = email.authorID
            }
            if emailReceiver == nil || emailReceiver!.characters.count == 0 {
                receiverTextField.becomeFirstResponder()
            } else if emailTitle == nil || emailTitle!.characters.count == 0 {
                titleTextField.becomeFirstResponder()
            } else {
                doneButton.isEnabled = true
                contentTextView.becomeFirstResponder()
                contentTextView.selectedRange = NSMakeRange(0, 0)
            }
        }
    }
    
    private func updateColor() {
        view.backgroundColor = AppTheme.shared.backgroundColor
        sendToLabel.textColor = AppTheme.shared.backgroundColor
        sendToLabel.backgroundColor = AppTheme.shared.lightTextColor
        titleHintLabel.textColor = AppTheme.shared.backgroundColor
        titleHintLabel.backgroundColor = AppTheme.shared.lightTextColor
        countLabel.textColor = AppTheme.shared.lightTextColor
        receiverTextField.textColor = AppTheme.shared.lightTextColor
        receiverTextField.attributedPlaceholder = NSAttributedString(string: "收信人",
                                                                     attributes: [NSForegroundColorAttributeName: AppTheme.shared.lightTextColor.withAlphaComponent(0.6)])
        receiverTextField.keyboardAppearance = setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
        titleTextField.textColor = AppTheme.shared.lightTextColor
        titleTextField.attributedPlaceholder = NSAttributedString(string: "添加标题",
                                                                  attributes: [NSForegroundColorAttributeName: AppTheme.shared.lightTextColor.withAlphaComponent(0.6)])
        titleTextField.keyboardAppearance = setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
        contentTextView.textColor = AppTheme.shared.textColor
        contentTextView.keyboardAppearance = setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        updateColor()
    }
    
    @objc private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func done(_ sender: UIBarButtonItem) {
        if let receiver = self.emailReceiver, let title = self.emailTitle, var content = self.emailContent {
            networkActivityIndicatorStart(withHUD: true)
            setEditable(false)
            DispatchQueue.global().async {
                var lines = content.components(separatedBy: .newlines)
                lines = lines.filter {
                    self.regx.numberOfMatches(in: $0, range: NSMakeRange(0, $0.characters.count)) == 0
                }
                content = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                content.append("\n\n" + self.signature)
                
                let result = self.api.sendMailTo(user: receiver, withTitle: title, content: content)
                print("send mail done. ret = \(result)")
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if self.api.errorCode == 0 {
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: .UIKeyboardWillChangeFrame,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(nightModeChanged(_:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        setupUI()
        setupMode()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo
        let animationDuration = info?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        var keyboardFrame = info?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        keyboardFrame = view.convert(keyboardFrame, from: view.window)
        let height = keyboardFrame.size.height
        keyboardHeight?.update(offset: -height - 5)
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
            countLabel.text = "\(textField.text!.characters.count)"
        }
        let userLength = receiverTextField.text!.characters.count
        let titleLength = titleTextField.text!.characters.count
        if userLength > 0 && titleLength > 0 {
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = false
        }
    }

}
