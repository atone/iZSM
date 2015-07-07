//
//  NYArticleContentCell.swift
//  zsmth
//
//  Created by Naitong Yu on 15/7/4.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit
import RSTWebViewController
import MessageUI

class ArticleContentCell: UITableViewCell, JTSImageViewControllerInteractionsDelegate, TTTAttributedLabelDelegate, MFMailComposeViewControllerDelegate {

    private var authorButton = UIButton.buttonWithType(.System) as! UIButton
    private var floorAndTimeLabel = UILabel(frame: CGRectZero)
    private var replyButton = UIButton.buttonWithType(.System) as! UIButton
    private var moreButton = UIButton.buttonWithType(.System) as! UIButton
    private var imageViews = [UIImageView]()

    private var contentLabel = TTTAttributedLabel(frame: CGRectZero)

    private var controller: UITableViewController?
    private var delegate: ComposeArticleControllerDelegate?

    private var article: SMArticle?
    private var displayFloor: Int = 0

    private let blankWidth: CGFloat = 4
    private let picNumPerLine: CGFloat = 3

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    func setup() {
        self.selectionStyle = .None
        self.tintColor = UIApplication.sharedApplication().keyWindow?.tintColor
        self.clipsToBounds = true

        authorButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        self.contentView.addSubview(authorButton)

        floorAndTimeLabel.font = UIFont.systemFontOfSize(15)
        self.contentView.addSubview(floorAndTimeLabel)

        replyButton.setTitle("回复", forState: .Normal)
        replyButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        replyButton.layer.cornerRadius = 4
        replyButton.layer.borderWidth = 1
        replyButton.layer.borderColor = tintColor.CGColor
        replyButton.clipsToBounds = true
        replyButton.addTarget(self, action: "reply:", forControlEvents: .TouchUpInside)
        self.contentView.addSubview(replyButton)

        moreButton.setTitle("•••", forState: .Normal)
        moreButton.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
        moreButton.layer.cornerRadius = 4
        moreButton.layer.borderWidth = 1
        moreButton.layer.borderColor = tintColor.CGColor
        moreButton.addTarget(self, action: "action:", forControlEvents: .TouchUpInside)
        self.contentView.addSubview(moreButton)

        contentLabel.lineBreakMode = .ByWordWrapping
        contentLabel.numberOfLines = 0
        contentLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        contentLabel.delegate = self
        contentLabel.verticalAlignment = .Top
        contentLabel.extendsLinkTouchArea = false
        contentLabel.linkAttributes = [NSForegroundColorAttributeName:tintColor]
        contentLabel.activeLinkAttributes = [NSForegroundColorAttributeName:tintColor.colorWithAlphaComponent(0.6)]
        self.contentView.addSubview(contentLabel)
    }



    func setData(displayFloor floor: Int, smarticle: SMArticle, controller: UITableViewController?, delegate: ComposeArticleControllerDelegate) {
        self.displayFloor = floor
        self.controller = controller
        self.delegate = delegate
        self.article = smarticle

        authorButton.setTitle(smarticle.authorID, forState: .Normal)
        let floorText = displayFloor == 0 ? "楼主" : "\(displayFloor)楼"
        floorAndTimeLabel.text = "\(floorText)  \(smarticle.timeString)"

        contentLabel.setText(smarticle.attributedBody)

        drawImagesWithInfo(smarticle.imageAtt)
    }

    //MARK: - Layout Subviews
    override func layoutSubviews() {
        super.layoutSubviews()

        authorButton.sizeToFit()
        authorButton.frame = CGRect(origin: CGPoint(x: 8, y: 0), size: authorButton.bounds.size)
        floorAndTimeLabel.sizeToFit()
        floorAndTimeLabel.frame = CGRect(origin: CGPoint(x: 8, y: 26), size: floorAndTimeLabel.bounds.size)
        replyButton.frame = CGRect(x: CGFloat(UIScreen.screenWidth()-94), y: 14, width: 40, height: 24)
        moreButton.frame = CGRect(x: CGFloat(UIScreen.screenWidth()-44), y: 14, width: 36, height: 24)

        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = contentView.bounds.width
        } else if imageViews.count > 1 {
            let oneImageLength = (contentView.bounds.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        contentLabel.frame = CGRect(x: 8, y: 52, width: CGFloat(UIScreen.screenWidth()-16), height: contentView.bounds.height - 60 - imageLength)

        let size = contentView.bounds.size
        if imageViews.count == 1 {
            imageViews.first!.frame = CGRect(x: 0, y: size.height - size.width, width: size.width, height: size.width)
        } else {
            for (index, imageView) in enumerate(imageViews) {
                let length = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                let startY = size.height - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
                let X = 0 + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)
                imageView.frame = CGRectMake(X, startY + offsetY, length, length)
            }
        }
    }

    //MARK: - Calculate Fitting Size
    override func sizeThatFits(size: CGSize) -> CGSize {
        let boundingSize = CGSizeMake(size.width-16, size.height)
        let rect = TTTAttributedLabel.sizeThatFitsAttributedString(article!.attributedBody, withConstraints: boundingSize, limitedToNumberOfLines: 0)
        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = size.width
        } else if imageViews.count > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        return CGSizeMake(size.width, 52 + ceil(rect.height) + 8 + imageLength)
    }

//    override func drawRect(rect: CGRect) {
//        article!.attributedBody.drawInRect(CGRect(x: 8, y: 52, width: CGFloat(UIScreen.screenWidth()-16), height: CGFloat.max))
//    }

    private func drawImagesWithInfo(imageAtt: [ImageInfo]) {
        // remove old image views
        for imageView in imageViews {
            imageView.removeFromSuperview()
        }
        imageViews.removeAll()

        // add new image views
        for imageInfo in imageAtt {
            let imageView = UIImageView()
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.kf_setImageWithURL(imageInfo.thumbnailURL)
            imageView.userInteractionEnabled = true
            let singleTap = UITapGestureRecognizer(target: self, action: "singleTapOnImage:")
            singleTap.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(singleTap)
            contentView.addSubview(imageView)
            imageViews.append(imageView)
        }
    }

    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        if let urlString = url.absoluteString {
            if urlString.hasPrefix("mailto") {
                let recipient = urlString.substringFromIndex(advance(urlString.startIndex, 7))
                let mailComposeViewController = MFMailComposeViewController()
                mailComposeViewController.mailComposeDelegate = self
                mailComposeViewController.setToRecipients([recipient])
                mailComposeViewController.modalPresentationStyle = .FormSheet
                mailComposeViewController.navigationBar.barStyle = .Black
                mailComposeViewController.navigationBar.tintColor = UIColor.whiteColor()
                controller?.presentViewController(mailComposeViewController, animated: true, completion: nil)

            } else {
                let webViewController = RSTWebViewController(URL: url)
                webViewController.showsDoneButton = true
                let navigationController = NYNavigationController(rootViewController: webViewController)
                controller?.presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }

    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller?.dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: - Action
    @objc private func singleTapOnImage(recognizer: UIGestureRecognizer) {
        if let imageView = recognizer.view as? UIImageView {
            let imageInfo = JTSImageInfo()

            if let index = find(imageViews, imageView) {
                imageInfo.imageURL = article?.imageAtt[index].fullImageURL
                imageInfo.placeholderImage = imageView.image
            } else {
                imageInfo.image = imageView.image
            }

            imageInfo.referenceRect = imageView.convertRect(imageView.bounds, toView: controller?.tableView)
            imageInfo.referenceView = controller?.tableView

            let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
            imageViewer.interactionsDelegate = self
            imageViewer.showFromViewController(controller, transition: ._FromOriginalPosition)
        }
    }

    func imageViewerDidLongPress(imageViewer: JTSImageViewController!, atRect rect: CGRect) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let savePhotoAction = UIAlertAction(title: "保存到相册", style: .Default) { [unowned self](alertAction) -> Void in
            let image = imageViewer.image
            UIImageWriteToSavedPhotosAlbum(image, self, "image:didFinishSavingWithError:contextInfo:", nil)
        }
        actionSheet.addAction(savePhotoAction)
        let copyPhotoAction = UIAlertAction(title: "复制到剪贴板", style: .Default) { [unowned self](alertAction) -> Void in
            UIPasteboard.generalPasteboard().image = imageViewer.image
            let hud = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow, animated: true)
            hud.mode = .Text
            hud.labelText = "复制成功"
            hud.hide(true, afterDelay: 1)
        }
        actionSheet.addAction(copyPhotoAction)
        actionSheet.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        actionSheet.popoverPresentationController?.sourceView = imageViewer.view
        actionSheet.popoverPresentationController?.sourceRect = rect
        imageViewer.presentViewController(actionSheet, animated: true, completion: nil)
    }

    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeMutablePointer<Void>) {
        let hud = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow, animated: true)
        hud.mode = .Text
        if error == nil {
            hud.labelText = "保存成功"
            hud.hide(true, afterDelay: 1)
        } else {
            hud.labelText = "请在设置中开启相册访问权限"
            hud.hide(true, afterDelay: 2)
        }
    }


    @objc private func reply(sender: UIButton) {
        self.reply(ByMail: false)
    }

    @objc private func action(sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let copyArticleAction = UIAlertAction(title: "复制文章", style: .Default) { action in
            UIPasteboard.generalPasteboard().string = self.article!.body
            let hud = MBProgressHUD.showHUDAddedTo(UIApplication.sharedApplication().keyWindow, animated: true)
            hud.mode = .Text
            hud.labelText = "复制成功"
            hud.hide(true, afterDelay: 1)
        }
        actionSheet.addAction(copyArticleAction)
        let replyByMailAction = UIAlertAction(title: "私信回复", style: .Default) { action in
            self.reply(ByMail: true)
        }
        actionSheet.addAction(replyByMailAction)
        let forwardAction = UIAlertAction(title: "转寄给用户", style: .Default) { action in
            self.forward(ToBoard: false)
        }
        actionSheet.addAction(forwardAction)
        let forwardToBoardAction = UIAlertAction(title: "转寄到版面", style: .Default) { action in
            self.forward(ToBoard: true)
        }
        actionSheet.addAction(forwardToBoardAction)
        let reportJunkAction = UIAlertAction(title: "举报不良内容", style: .Destructive) { action in
            self.reportJunk()
        }
        actionSheet.addAction(reportJunkAction)
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        controller?.presentViewController(actionSheet, animated: true, completion: nil)
    }

    private func reply(#ByMail: Bool) {
        if let cavc = self.controller?.storyboard?.instantiateViewControllerWithIdentifier("ComposeArticleController") as? ComposeArticleController {
            cavc.boardID = self.article?.boardID
            cavc.delegate = self.delegate
            cavc.replyMode = true
            cavc.originalArticle = self.article
            cavc.replyByMail = ByMail
            let navigationController = UINavigationController(rootViewController: cavc)
            navigationController.modalPresentationStyle = .FormSheet
            controller?.presentViewController(navigationController, animated: true, completion: nil)
        }
    }

    private func reportJunk() {
        let api = SmthAPI()
        let hud = MBProgressHUD.showHUDAddedTo(self.controller?.navigationController?.view, animated: true)

        var adminID = "SYSOP"

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let boardID = self.article?.boardID, boards = api.queryBoard(boardID) {
                for board in boards {
                    if board.boardID == boardID {
                        let managers = split(board.manager) { $0 == " " }
                        if managers.count > 0 && !managers[0].isEmpty {
                            adminID = managers[0]
                        }
                        break
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                hud.hide(true)
                let alert = UIAlertController(title: "举报不良内容", message: "您将要向 \(self.article!.boardID) 版版主 \(adminID) 举报用户 \(self.article!.authorID) 在帖子【\(self.article!.subject)】中发表的不良内容。请您输入举报原因：", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler { textField in
                    textField.placeholder = "如垃圾广告、色情内容、人身攻击等"
                    textField.returnKeyType = .Done
                }
                let okAction = UIAlertAction(title: "举报", style: .Default) { [unowned alert, unowned self] action in
                    if let textField = alert.textFields?.first as? UITextField {
                        let hud = MBProgressHUD.showHUDAddedTo(self.controller?.navigationController?.view, animated: true)
                        if textField.text == nil || textField.text.isEmpty {
                            hud.mode = .Text
                            hud.labelText = "举报原因不能为空"
                            hud.hide(true, afterDelay: 1)
                            return
                        }
                        let title = "举报用户 \(self.article!.authorID) 在 \(self.article!.boardID) 版中发表的不良内容"
                        let body = "举报原因：\(textField.text)\n\n【以下为被举报的帖子内容】\n作者：\(self.article!.authorID)\n信区：\(self.article!.boardID)\n标题：\(self.article!.subject)\n时间：\(self.article!.timeString)\n\n\(self.article!.body)\n"
                        networkActivityIndicatorStart()
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            api.sendMailTo(adminID, withTitle: title, content: body)
                            dispatch_async(dispatch_get_main_queue()) {
                                networkActivityIndicatorStop()
                                hud.mode = .Text
                                if api.errorCode == 0 {
                                    hud.labelText = "举报成功"
                                } else if let errorDescription = api.errorDescription where errorDescription != "" {
                                    hud.labelText = errorDescription
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
                self.controller?.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }

    private func forward(#ToBoard: Bool) {
        if let originalArticle = self.article {
            let api = SmthAPI()
            let alert = UIAlertController(title: (ToBoard ? "转寄到版面":"转寄给用户"), message: nil, preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler{ textField in
                textField.placeholder = ToBoard ? "版面ID" : "收件人，不填默认寄给自己"
                textField.keyboardType = ToBoard ? UIKeyboardType.ASCIICapable : UIKeyboardType.EmailAddress
                textField.autocorrectionType = .No
                textField.returnKeyType = .Send
            }
            let okAction = UIAlertAction(title: "确定", style: .Default) { [unowned alert, unowned self] action in
                if let textField = alert.textFields?.first as? UITextField {
                    let hud = MBProgressHUD.showHUDAddedTo(self.controller?.navigationController?.view, animated: true)
                    networkActivityIndicatorStart()
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        if ToBoard {
                            api.crossArticle(originalArticle.id, fromBoard: self.article!.boardID, toBoard: textField.text)
                        } else {
                            let user = textField.text.isEmpty ? AppSetting.sharedSetting().username! : textField.text
                            api.forwardArticle(originalArticle.id, inBoard: self.article!.boardID, toUser: user)
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            networkActivityIndicatorStop()
                            hud.mode = .Text
                            if api.errorCode == 0 {
                                hud.labelText = "转寄成功"
                            } else if let errorDescription = api.errorDescription where errorDescription != "" {
                                hud.labelText = errorDescription
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
            self.controller?.presentViewController(alert, animated: true, completion: nil)
        }
    }


}
