//
//  ComposeArticleController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import SnapKit
import SVProgressHUD
import TZImagePickerController

class ComposeArticleController: UIViewController, UITextFieldDelegate {
    
    enum Mode {
        case post
        case reply
        case replyByMail
        case modify
    }
    
    private let margin: CGFloat = 8
    private let cornerRadius: CGFloat = 4
    
    private let titleHintLabel = NTLabel()
    private let titleTextField = UITextField()
    private let countLabel = UILabel()
    private let contentTextView = UITextView()
    private lazy var doneButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
    }()
    private lazy var cancelButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
    }()
    private lazy var photoButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addPhoto(_:)))
    }()
    private lazy var attachScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    private lazy var attachStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 5
        return stack
    }()
    
    var boardID: String?
    var completionHandler: (() -> Void)?
    
    var mode: Mode = .post
    var article: SMArticle?
    
    private let signature = AppSetting.shared.signature
    private let addDeviceSignature = AppSetting.shared.addDeviceSignature
    
    private var articleTitle: String? {
        get { return titleTextField.text }
        set { titleTextField.text = newValue }
    }
    
    private var articleContent: String? {
        get { return contentTextView.text }
        set { contentTextView.text = newValue }
    }
    
    private var contentViewOffset: Constraint?
    private var keyboardHeight: CGFloat = 0
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    
    private let maxAttachNumber = 8
    private var attachedAssets = [PHAsset]()
    private var attachedImages = [UIImage]() {
        didSet {
            if oldValue.count == 0 && attachedImages.count > 0 {
                attachScrollView.isHidden = false
                updateContentLayout()
            } else if oldValue.count > 0 && attachedImages.count == 0 {
                attachScrollView.isHidden = true
                updateContentLayout()
            }
        }
    }
    
    private func setEditable(_ editable: Bool) {
        doneButton.isEnabled = editable
        cancelButton.isEnabled = editable
        titleTextField.isEnabled = editable
        contentTextView.isEditable = editable
        if mode == .post || mode == .reply {
            photoButton.isEnabled = editable
        }
        if attachedImages.count > 0 {
            attachScrollView.isUserInteractionEnabled = editable
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        titleHintLabel.text = "标题"
        titleHintLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleHintLabel.textAlignment = .center
        titleHintLabel.textColor = .systemBackground
        titleHintLabel.backgroundColor = .secondaryLabel
        let m = cornerRadius / 2
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
        
        if mode == .replyByMail || mode == .modify {
            navigationItem.rightBarButtonItems = [doneButton]
        } else {
            navigationItem.rightBarButtonItems = [doneButton, photoButton]
        }
        navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubview(titleHintLabel)
        view.addSubview(titleTextField)
        view.addSubview(countLabel)
        view.addSubview(contentTextView)
        
        if mode == .post || mode == .reply {
            attachScrollView.isHidden = true
            view.addSubview(attachScrollView)
            attachScrollView.addSubview(attachStack)
        }
        
        titleHintLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(margin)
        }
        titleTextField.snp.makeConstraints { (make) in
            make.leading.equalTo(titleHintLabel.snp.trailing).offset(margin)
            make.lastBaseline.equalTo(titleHintLabel)
        }
        countLabel.snp.makeConstraints { (make) in
            make.lastBaseline.equalTo(titleTextField)
            make.trailing.equalTo(view.snp.trailingMargin)
            make.leading.equalTo(titleTextField.snp.trailing).offset(margin)
        }
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleHintLabel)
            make.trailing.equalTo(countLabel)
            self.contentViewOffset = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-margin).constraint
            make.top.equalTo(countLabel.snp.bottom).offset(margin)
        }
        
        if mode == .post || mode == .reply {
            attachScrollView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.top.equalTo(contentTextView.snp.bottom).offset(margin)
                make.height.equalTo(100)
            }
            attachStack.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.height.equalTo(100)
            }
        }
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
                countLabel.text = "\(articleTitle!.count)"
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        case .replyByMail:
            title = "私信回复"
            doneButton.isEnabled = true
            if let article = article {
                articleTitle = article.replySubject
                articleContent = article.quotBody
                countLabel.text = "\(articleTitle!.count)"
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        case .modify:
            title = "修改文章"
            doneButton.isEnabled = true
            if let article = article {
                articleTitle = article.subject
                articleContent = article.body
                countLabel.text = "\(articleTitle!.count)"
            }
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        }
    }
    
    @objc private func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func done(_ sender: UIBarButtonItem) {
        if let boardID = self.boardID, let title = self.articleTitle, var content = self.articleContent {
            networkActivityIndicatorStart(withHUD: true)
            setEditable(false)
            DispatchQueue.global().async {
                for index in 0..<self.attachedImages.count {
                    DispatchQueue.main.async {
                        SVProgressHUD.show(withStatus: "正在上传: \(index + 1) / \(self.attachedImages.count)")
                    }
                    let _ = self.api.uploadAttImage(image: self.attachedImages[index], index: index + 1)
                }
                
                let lines = content.components(separatedBy: .newlines).map {
                    $0.trimmingCharacters(in: .whitespaces)
                }
                content = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if self.addDeviceSignature {
                    content.append("\n\n" + self.signature)
                }
                
                switch self.mode {
                case .post:
                    let result = self.api.postArticle(title: title, content: content, inBoard: boardID)
                    dPrint("post article done. article_id = \(result)")
                case .reply:
                    if let article = self.article {
                        let result = self.api.replyArticle(articleID: article.id, title: title, content: content, inBoard: boardID)
                        dPrint("reply article done. article_id = \(result)")
                    } else {
                        dPrint("error: no article to reply")
                    }
                case .replyByMail:
                    if let article = self.article {
                        let result = self.api.sendMailTo(user: article.authorID, withTitle: title, content: content)
                        dPrint("reply by mail done. ret = \(result)")
                    } else {
                        dPrint("error: no article to reply")
                    }
                case .modify:
                    if let article = self.article {
                        let result = self.api.modifyArticle(articleID: article.id, title: title, content: content, inBoard: boardID)
                        dPrint("modify article done. ret = \(result)")
                    } else {
                        dPrint("error: no article to modify")
                    }
                }
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if self.api.errorCode == 0 {
                        switch self.mode {
                        case .post:
                            SVProgressHUD.showSuccess(withStatus: "发表成功")
                        case .reply, .replyByMail:
                            SVProgressHUD.showSuccess(withStatus: "回复成功")
                        case .modify:
                            SVProgressHUD.showSuccess(withStatus: "修改成功")
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
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        setupUI()
        setupMode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    @objc private func addPhoto(_ sender: UIBarButtonItem) {
        let imagePicker = TZImagePickerController(maxImagesCount: maxAttachNumber, delegate: self)!
        imagePicker.modalPresentationStyle = .formSheet
        imagePicker.naviBgColor = navigationController?.navigationBar.barTintColor
        imagePicker.naviTitleColor = navigationController?.navigationBar.tintColor
        imagePicker.selectedAssets = NSMutableArray(array: attachedAssets)
        imagePicker.allowPickingVideo = false
        imagePicker.allowPickingOriginalPhoto = false
        imagePicker.photoWidth = 1024
        present(imagePicker, animated: true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo
        var keyboardFrame = info?[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        keyboardFrame = view.convert(keyboardFrame, from: view.window)
        keyboardHeight = max(view.bounds.height - view.safeAreaInsets.bottom - keyboardFrame.origin.y, 0)
        updateContentLayout()
    }
    
    private func updateContentLayout() {
        if attachedImages.count > 0 {
            contentViewOffset?.update(offset: -keyboardHeight - margin - 100)
        } else {
            contentViewOffset?.update(offset: -keyboardHeight - margin)
        }
        self.view.layoutIfNeeded()
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return false
    }
    
    @objc private func changeDoneButton(_ textField: UITextField) {
        if let length = textField.text?.count {
            countLabel.text = "\(length)"
            if length > 0 {
                doneButton.isEnabled = true
            } else {
                doneButton.isEnabled = false
            }
        }
    }
}

extension ComposeArticleController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        contentTextView.becomeFirstResponder()
        if let photos = photos, let assets = assets as? [PHAsset] {
            attachStack.removeAllSubviews()
            for photo in photos {
                let view = AttachImageView()
                view.image = photo
                view.delegate = self
                attachStack.addArrangedSubview(view)
            }
            attachedImages = photos
            attachedAssets = assets
        }
    }
    
    func tz_imagePickerControllerDidCancel(_ picker: TZImagePickerController!) {
        contentTextView.becomeFirstResponder()
    }
}

extension ComposeArticleController: AttachImageViewDelegate {
    func deleteButtonPressed(in attachImageView: AttachImageView) {
        if let image = attachImageView.image, let idx = attachedImages.firstIndex(of: image) {
            attachedImages.remove(at: idx)
            attachedAssets.remove(at: idx)
        }
        attachStack.removeArrangedSubview(attachImageView)
        attachImageView.removeFromSuperview()
    }
    
    func imageTapped(in attachImageView: AttachImageView) {
        if let image = attachImageView.image, let idx = attachedImages.firstIndex(of: image) {
            let imagePicker = TZImagePickerController(selectedAssets: NSMutableArray(array: attachedAssets), selectedPhotos: NSMutableArray(array: attachedImages), index: idx)!
            imagePicker.didFinishPickingPhotosHandle = { [unowned self] (_, _, _) in
                self.contentTextView.becomeFirstResponder()
            }
            imagePicker.imagePickerControllerDidCancelHandle = { [unowned self] in
                self.contentTextView.becomeFirstResponder()
            }
            present(imagePicker, animated: true)
        }
    }
}
