//
//  ReferContentViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/21.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ReferContentViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    
    var reference: SMReference?
    var replyMe: Bool = true

    private let api = SmthAPI()
    private var article: SMArticle?

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "preferredFontSizeChanged:",
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)
        let replyItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: "reply:")
        let actionItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "action:")
        navigationItem.rightBarButtonItems = [actionItem, replyItem]
        fetchData()
    }

    func reply(sender: UIBarButtonItem) {
        if let article = self.article, reference = self.reference {
            let cavc = storyboard?.instantiateViewControllerWithIdentifier("ComposeArticleController") as! ComposeArticleController
            cavc.boardID = reference.boardID
            cavc.replyMode = true
            cavc.originalArticle = article
            cavc.modalPresentationStyle = .FormSheet
            presentViewController(cavc, animated: true, completion: nil)
        }
    }

    func action(sender: UIBarButtonItem) {
        if article == nil { return }
        if let reference = self.reference {
            let acvc = self.storyboard?.instantiateViewControllerWithIdentifier("ArticleContentViewController") as! ArticleContentViewController
            acvc.articleID = reference.groupID
            acvc.boardID = reference.boardID
            var title = reference.subject
            if title.hasPrefix("Re: ") {
                title = title.substringFromIndex(advance(title.startIndex, 4))
            }
            acvc.title = title
            acvc.fromTopTen = true
            acvc.hidesBottomBarWhenPushed = true
            self.showViewController(acvc, sender: sender)
        }
    }

    private func fetchData() {
        titleLabel?.text = nil
        userButton?.setTitle(nil, forState: .Normal)
        timeLabel?.text = nil
        contentTextView?.text = nil
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let reference = self.reference {
                self.article = self.api.getArticleInBoard(reference.boardID, articleID: reference.id)
                //需要设置提醒已读
                if self.api.errorCode == 0 || self.api.errorCode == 11011 { //11011:文章不存在，已经被删除
                    let referMode: SmthAPI.ReferMode = self.replyMe ? .ReplyToMe : .AtMe
                    self.api.setReferRead(mode: referMode, atPosition: reference.position)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                if let article = self.article {
                    hud.hide(true)
                    if self.replyMe {
                        self.title = "\(article.authorID) 回复了我"
                    } else {
                        self.title = "\(article.authorID) @了我"
                    }
                    self.titleLabel?.text = article.subject
                    self.userButton?.setTitle(article.authorID, forState: .Normal)
                    self.timeLabel?.text = self.stringFromDate(article.time)
                    self.contentTextView?.attributedText = self.attributedStringFromContentString(article.body)
                } else {
                    hud.mode = .Text
                    hud.labelText = "文章可能已被删除"
                    hud.hide(true, afterDelay: 1)
                }
            }
        }
    }

    func preferredFontSizeChanged(notification: NSNotification) {
        titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        userButton?.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        timeLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        contentTextView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
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
