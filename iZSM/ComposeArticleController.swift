//
//  ComposeArticleController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import MobileCoreServices
import SnapKit
import SVProgressHUD

class ComposeArticleController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    enum Mode {
        case post
        case reply
        case replyByMail
        case modify
    }
    
    private let titleHintLabel = UILabel()
    private let titleTextField = UITextField()
    private let contentTextView = UITextView()
    private let countLabel = UILabel()
    private lazy var doneButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }()
    
    var boardID: String?
    var completionHandler: (() -> Void)?
    
    var mode: Mode = .post
    var article: SMArticle?
    
    private let signature = AppSetting.shared.signature
    
    private var articleTitle: String? {
        get { return titleTextField.text }
        set { titleTextField.text = newValue }
    }
    
    private var articleContent: String? {
        get { return contentTextView.text }
        set { contentTextView.text = newValue }
    }
    
    private var keyboardHeight: Constraint?
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    
    private var attachedImage: UIImage? //图片附件，如果为nil，则表示不含附件
    
    private func setEditable(_ editable: Bool) {
        titleTextField.isEnabled = editable
        contentTextView.isEditable = editable
    }
    
    private func setupUI() {
        let cornerRadius: CGFloat = 4
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
        
        if mode == .replyByMail || mode == .modify {
            navigationItem.rightBarButtonItems = [doneButton]
        } else {
            let addPhoto = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addPhoto(_:)))
            navigationItem.rightBarButtonItems = [doneButton, addPhoto]
        }
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = cancel
        
        view.addSubview(titleHintLabel)
        view.addSubview(titleTextField)
        view.addSubview(countLabel)
        view.addSubview(contentTextView)
        
        titleHintLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(5)
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
            make.trailing.equalTo(view.snp.trailingMargin)
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
    
    private func updateColor() {
        view.backgroundColor = AppTheme.shared.backgroundColor
        titleHintLabel.textColor = AppTheme.shared.backgroundColor
        titleHintLabel.backgroundColor = AppTheme.shared.lightTextColor
        countLabel.textColor = AppTheme.shared.lightTextColor
        titleTextField.textColor = AppTheme.shared.lightTextColor
        titleTextField.attributedPlaceholder = NSAttributedString(string: "添加标题",
                                                                  attributes: [NSForegroundColorAttributeName: AppTheme.shared.lightTextColor.withAlphaComponent(0.6)])
        titleTextField.keyboardAppearance = setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
        contentTextView.textColor = AppTheme.shared.textColor
        contentTextView.keyboardAppearance = setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
    }
    
    private func setupMode() {
        switch mode {
        case .post:
            title = "发表文章"
            doneButton.isEnabled = false
            titleTextField.becomeFirstResponder()
        case .reply:
            title = "回复文章"
            doneButton.isEnabled = true
            if let article = article {
                articleTitle = article.replySubject
                articleContent = article.quotBody
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        case .replyByMail:
            title = "私信回复"
            doneButton.isEnabled = true
            if let article = article {
                articleTitle = article.replySubject
                articleContent = article.quotBody
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        case .modify:
            title = "修改文章"
            doneButton.isEnabled = true
            if let article = article {
                articleTitle = article.subject
                articleContent = article.body
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        }
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        updateColor()
    }
    
    @objc private func cancel(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc private func done(_ sender: UIBarButtonItem) {
        if let boardID = self.boardID, let title = self.articleTitle, var content = self.articleContent {
            networkActivityIndicatorStart(withHUD: true)
            setEditable(false)
            DispatchQueue.global().async {
                var attachmentUploadSuccessFul = true
                if let image = self.attachedImage {
                    attachmentUploadSuccessFul = (self.api.uploadAttImage(image: image, index: 1) != nil)
                }
                
                var lines = content.components(separatedBy: .newlines)
                lines = lines.filter { !$0.contains(self.signature) }
                content = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                content.append("\n\n" + self.signature)
                
                switch self.mode {
                case .post:
                    let result = self.api.postArticle(title: title, content: content, inBoard: boardID)
                    print("post article done. article_id = \(result)")
                case .reply:
                    if let article = self.article {
                        let result = self.api.replyArticle(articleID: article.id, title: title, content: content, inBoard: boardID)
                        print("reply article done. article_id = \(result)")
                    } else {
                        print("error: no article to reply")
                    }
                case .replyByMail:
                    if let article = self.article {
                        let result = self.api.sendMailTo(user: article.authorID, withTitle: title, content: content)
                        print("reply by mail done. ret = \(result)")
                    } else {
                        print("error: no article to reply")
                    }
                case .modify:
                    if let article = self.article {
                        let result = self.api.modifyArticle(articleID: article.id, title: title, content: content, inBoard: boardID)
                        print("modify article done. ret = \(result)")
                    } else {
                        print("error: no article to modify")
                    }
                }
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if self.api.errorCode == 0 {
                        if attachmentUploadSuccessFul {
                            switch self.mode {
                            case .post:
                                SVProgressHUD.showSuccess(withStatus: "发表成功")
                            case .reply, .replyByMail:
                                SVProgressHUD.showSuccess(withStatus: "回复成功")
                            case .modify:
                                SVProgressHUD.showSuccess(withStatus: "修改成功")
                            }
                        } else {
                            SVProgressHUD.showError(withStatus: "附件上传失败")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.completionHandler?()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    @objc private func addPhoto(_ sender: UIBarButtonItem) {
        if attachedImage == nil {
            let actionSheet = UIAlertController(title: "添加照片", message: nil, preferredStyle: .actionSheet)
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let camera = UIAlertAction(title: "从图库中选择", style: .default) { [unowned self] action in
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = .photoLibrary
                    picker.modalPresentationStyle = .formSheet
                    self.present(picker, animated: true, completion: nil)
                }
                actionSheet.addAction(camera)
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let camera = UIAlertAction(title: "使用相机拍照", style: .default) { [unowned self] action in
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = .camera
                    self.present(picker, animated: true, completion: nil)
                }
                actionSheet.addAction(camera)
            }
            actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            actionSheet.popoverPresentationController?.barButtonItem = sender
            present(actionSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "是否删除图片附件？", message: nil, preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "删除", style: .destructive)  { [unowned self] action in
                self.attachedImage = nil
            }
            alert.addAction(deleteAction)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        let type = info[UIImagePickerControllerMediaType] as! String
        if type == kUTTypeImage as String {
            attachedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo
        let animationDuration = info?[UIKeyboardAnimationDurationUserInfoKey] as! Double
        var keyboardFrame = info?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        keyboardFrame = view.convert(keyboardFrame, from: view.window)
        let height = keyboardFrame.size.height
        keyboardHeight?.update(offset: -height - 5)
        UIView.animate(withDuration: animationDuration, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return false
    }
    
    @objc private func changeDoneButton(_ textField: UITextField) {
        if let length = textField.text?.characters.count {
            countLabel.text = "\(length)"
            if length > 0 {
                doneButton.isEnabled = true
            } else {
                doneButton.isEnabled = false
            }
        }
    }
}
