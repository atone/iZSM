//
//  ComposeArticleController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/18.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ComposeArticleController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var boardID: String?
    var delegate: ComposeArticleControllerDelegate?

    var replyMode: Bool = false
    var replyByMail: Bool = false
    var originalArticle: SMArticle?

    let signature = "\n- 来自「最水木」iOS客户端"

    var articleTitle: String? {
        get { return titleTextField?.text }
        set { titleTextField?.text = newValue }
    }

    var articleContent: String? {
        get { return contentTextView?.text }
        set { contentTextView?.text = newValue }
    }

    @IBOutlet weak var titleHintLabel: UILabel! {
        didSet { titleHintLabel?.layer.cornerRadius = 2 }
    }
    @IBOutlet weak var titleTextField: UITextField! {
        didSet {
            titleTextField?.delegate = self
            titleTextField?.addTarget(self, action: #selector(ComposeArticleController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        }
    }
    @IBOutlet weak var contentTextView: UITextView!

    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!

    @IBOutlet weak var keyboardHeight: NSLayoutConstraint!

    private let api = SmthAPI()
    private let setting = AppSetting.sharedSetting

    private var attachedImage: UIImage? //图片附件，如果为nil，则表示不含附件

    @IBAction func cancel(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func done(sender: UIBarButtonItem) {
        if let boardID = self.boardID {
            let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var attachmentUploadSuccessFul = true
                if let image = self.attachedImage {
                    attachmentUploadSuccessFul = self.api.uploadImage(image)
                }

                var content = self.articleContent!
                if content.hasSuffix("\n") {
                    content = content + self.signature
                } else {
                    content = content + "\n" + self.signature
                }
                if self.replyMode {
                    if self.replyByMail {
                        self.api.sendMailTo(self.originalArticle!.authorID, withTitle: self.articleTitle!, content: content)
                    } else {
                        self.api.replyArticle(self.originalArticle!.id, title: self.articleTitle!, content: content, inBoard: boardID)
                    }
                } else {
                    self.api.postArticle(title: self.articleTitle!, content: content, inBoard: boardID)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    hud.mode = .Text
                    if self.api.errorCode == 0 {
                        if attachmentUploadSuccessFul {
                            hud.labelText = self.replyMode ? "回复成功":"发表成功"
                        } else {
                            hud.labelText = "附件上传失败"
                        }
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                            self.delegate?.articleDidPosted()
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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ComposeArticleController.keyboardWillShow(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
        api.resetStatus() //发文/回复文章时，必须手动resetStatus，因为中间可能会有添加附件等操作
        if !replyByMail { //发送邮件时，不支持添加附件
            let addPhoto = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: #selector(ComposeArticleController.addPhoto(_:)))
            navigationItem.rightBarButtonItems?.append(addPhoto)
        }
        if replyMode {
            handleReplyMode()
            contentTextView.becomeFirstResponder()
            contentTextView.selectedRange = NSMakeRange(0, 0)
        } else {
            titleTextField.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    func addPhoto(sender: UIBarButtonItem) {
        if attachedImage == nil {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
                let camera = UIAlertAction(title: "从图库中选择", style: .Default) { [unowned self] action in
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = .PhotoLibrary
                    picker.modalPresentationStyle = .FormSheet
                    self.presentViewController(picker, animated: true, completion: nil)
                }
                actionSheet.addAction(camera)
            }
            if UIImagePickerController.isSourceTypeAvailable(.Camera) {
                let camera = UIAlertAction(title: "使用相机拍照", style: .Default) { [unowned self] action in
                    let picker = UIImagePickerController()
                    picker.delegate = self
                    picker.sourceType = .Camera
                    self.presentViewController(picker, animated: true, completion: nil)
                }
                actionSheet.addAction(camera)
            }
            actionSheet.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            actionSheet.popoverPresentationController?.barButtonItem = sender
            presentViewController(actionSheet, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "是否删除图片附件？", message: nil, preferredStyle: .Alert)
            let deleteAction = UIAlertAction(title: "删除", style: .Destructive)  { [unowned self] action in
                self.attachedImage = nil
            }
            alert.addAction(deleteAction)
            alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        let type = info[UIImagePickerControllerMediaType] as! String
        if type == "public.image" {
            attachedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
    }

    func handleReplyMode() {
        title = replyByMail ? "私信回复" : "回复文章"
        doneButton.enabled = true
        if let article = originalArticle {
            // 处理标题
            if article.subject.lowercaseString.hasPrefix("re:") {
                articleTitle = article.subject
            } else {
                articleTitle = "Re: " + article.subject
            }
            countLabel.text = "\((articleTitle!).characters.count)"
            // 处理内容
            var tempContent = "\n【 在 \(article.authorID) 的大作中提到: 】\n"
            var origContent = article.body + "\n"

            if let range = origContent.rangeOfString(signature) {
                origContent.replaceRange(range, with: "")
            }

            for _ in 1...3 {
                if let linebreak = origContent.rangeOfString("\n") {
                    tempContent += (": " + origContent.substringToIndex(linebreak.endIndex))
                    origContent = origContent.substringFromIndex(linebreak.endIndex)
                } else {
                    break
                }
            }
            if origContent.rangeOfString("\n") != nil {
                tempContent += ": ....................\n"
            }

            articleContent = tempContent
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        contentTextView.becomeFirstResponder()
        return false
    }

    func textFieldDidChange(textField: UITextField) {
        if let length = textField.text?.characters.count {
            countLabel?.text = "\(length)"
            if length > 0 {
                doneButton.enabled = true
            } else {
                doneButton.enabled = false
            }
        }
    }



}

protocol ComposeArticleControllerDelegate {
    func articleDidPosted()
}
