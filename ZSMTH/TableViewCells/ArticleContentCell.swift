//
//  ArticleContentTableViewCell.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/7.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//
//  This will be changed a lot

import UIKit

class ArticleContentCell: UITableViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!

    private var controller: UITableViewController?
    private var delegate: ComposeArticleControllerDelegate?
    private var smarticle: SMArticle?
    private var boardID: String?

    private var timeString: String?

    private var imageViews = [UIImageView]()

    private var blankWidth: CGFloat = 4
    private var picNumPerLine: CGFloat = 3

    private var author: String? {
        get {
            return authorLabel?.text
        }
        set {
            authorLabel?.text = newValue
            authorLabel?.textColor = UIApplication.sharedApplication().keyWindow?.tintColor
        }
    }

    private var floorAndTime: String? {
        get {
            return floorLabel?.text
        }
        set {
            floorLabel?.text = newValue
        }
    }

    private var content: NSAttributedString? {
        get {
            return contentLabel?.attributedText
        }
        set {
            contentLabel?.attributedText = newValue
        }
    }

    private var imageAtt: [ImageInfo]? {
        didSet {
            if let imageAtt = self.imageAtt {
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
        }

        willSet {
            for imageView in imageViews {
                imageView.removeFromSuperview()
            }
            imageViews.removeAll()
        }
    }

    private func indexForImageView(imageView: UIImageView) -> Int? {
        for (index,v) in enumerate(imageViews) {
            if v === imageView {
                return index
            }
        }
        return nil
    }

    func setData(#floor: Int, boardID: String, article: RichArticle, smarticle: SMArticle, controller: UITableViewController?, delegate: ComposeArticleControllerDelegate) {
        author = article.author
        let floorText = floor == 0 ? "楼主" : "\(floor)楼"
        floorAndTime = "\(floorText)  \(article.time)"
        timeString = article.time
        content = article.body
        imageAtt = article.imageAtt

        self.boardID = boardID
        self.controller = controller
        self.delegate = delegate
        self.smarticle = smarticle
    }

    func singleTapOnImage(recognizer: UIGestureRecognizer) {
        if let imageView = recognizer.view as? UIImageView {
            let imageInfo = JTSImageInfo()
            //imageInfo.image = imageView.image
            if let index = indexForImageView(imageView) {
                imageInfo.imageURL = imageAtt?[index].fullImageURL
                imageInfo.placeholderImage = imageView.image
            } else {
                imageInfo.image = imageView.image
            }

            imageInfo.referenceRect = imageView.convertRect(imageView.bounds, toView: controller?.tableView)
            imageInfo.referenceView = controller?.tableView

            let imageViewer = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .Blurred)
            imageViewer.showFromViewController(controller, transition: ._FromOriginalPosition)
        }
    }

    @IBAction func reply(sender: UIButton) {
        self.reply(ByMail: false)
    }

    @IBAction func action(sender: UIButton) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
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
            cavc.boardID = self.boardID
            cavc.delegate = self.delegate
            cavc.replyMode = true
            cavc.originalArticle = self.smarticle
            cavc.replyByMail = ByMail
            cavc.modalPresentationStyle = .FormSheet
            controller?.presentViewController(cavc, animated: true, completion: nil)
        }
    }

    private func reportJunk() {
        let api = SmthAPI()
        let hud = MBProgressHUD.showHUDAddedTo(self.controller?.navigationController?.view, animated: true)

        var adminID = "SYSOP"

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let boardID = self.boardID, boards = api.queryBoard(boardID) {
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
                let alert = UIAlertController(title: "举报不良内容", message: "您将要向 \(self.boardID!) 版版主 \(adminID) 举报用户 \(self.smarticle!.authorID) 在帖子【\(self.smarticle!.subject)】中发表的不良内容。请您输入举报原因：", preferredStyle: .Alert)
                alert.addTextFieldWithConfigurationHandler { textField in
                    textField.placeholder = "如垃圾广告、色情内容、人身攻击等"
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
                        let title = "举报用户 \(self.smarticle!.authorID) 在 \(self.boardID!) 版中发表的不良内容"
                        let body = "举报原因：\(textField.text)\n\n【以下为被举报的帖子内容】\n作者：\(self.smarticle!.authorID)\n信区：\(self.boardID!)\n标题：\(self.smarticle!.subject)\n时间：\(self.timeString!)\n\n\(self.smarticle!.body)\n"
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
        if let originalArticle = self.smarticle {
            let api = SmthAPI()
            let alert = UIAlertController(title: (ToBoard ? "转寄到版面":"转寄给用户"), message: nil, preferredStyle: .Alert)
            alert.addTextFieldWithConfigurationHandler{ textField in
                textField.placeholder = ToBoard ? "版面ID":"收件人"
            }
            let okAction = UIAlertAction(title: "确定", style: .Default) { [unowned alert, unowned self] action in
                if let textField = alert.textFields?.first as? UITextField {
                    let hud = MBProgressHUD.showHUDAddedTo(self.controller?.navigationController?.view, animated: true)
                    networkActivityIndicatorStart()
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        if ToBoard {
                            api.crossArticle(originalArticle.id, fromBoard: self.boardID!, toBoard: textField.text)
                        } else {
                            api.forwardArticle(originalArticle.id, inBoard: self.boardID!, toUser: textField.text)
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

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = contentView.bounds.size

        if imageViews.count == 1 {
            imageViews.first!.frame = CGRectMake(0, size.height - size.width, size.width, size.width)
        } else {
            for (index,imageView) in enumerate(imageViews) {
                let length = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
                let startY = size.height - ((length + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth)
                let offsetY = (length + blankWidth) * CGFloat(index / Int(picNumPerLine))
                let X = 0 + CGFloat(index % Int(picNumPerLine)) * (length + blankWidth)

                imageView.frame = CGRectMake(X, startY + offsetY, length, length)
            }
        }
    }

    override func sizeThatFits(size: CGSize) -> CGSize {
        let boundingSize = CGSizeMake(size.width-16, size.height)
        let rect = content!.boundingRectWithSize(boundingSize, options: .UsesLineFragmentOrigin, context: nil)
        var imageLength: CGFloat = 0
        if imageViews.count == 1 {
            imageLength = size.width
        } else if imageViews.count > 1 {
            let oneImageLength = (size.width - (picNumPerLine - 1) * blankWidth) / picNumPerLine
            imageLength = (oneImageLength + blankWidth) * ceil(CGFloat(imageViews.count) / picNumPerLine) - blankWidth
        }
        return CGSizeMake(size.width, 52 + ceil(rect.height) + imageLength)
    }
}
