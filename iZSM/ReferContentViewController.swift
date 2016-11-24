//
//  ReferContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SnapKit
import SVProgressHUD
import SafariServices

class ReferContentViewController: UIViewController, UITextViewDelegate {
    
    let titleLabel = UILabel()
    let userButton = UIButton(type: .system)
    let timeLabel = UILabel()
    let contentTextView = UITextView()
    
    var reference: SMReference?
    var replyMe: Bool = true
    private let api = SmthAPI()
    private var article: SMArticle?
    
    func setupUI() {
        view.backgroundColor = UIColor.white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.textColor = UIColor.gray
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
        contentTextView.isEditable = false
        contentTextView.dataDetectorTypes = [.phoneNumber, .link]
        view.addSubview(titleLabel)
        view.addSubview(userButton)
        view.addSubview(timeLabel)
        view.addSubview(contentTextView)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(view.snp.leadingMargin)
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(5)
            make.trailing.equalTo(view.snp.trailingMargin)
        }
        userButton.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(titleLabel)
            make.centerY.equalTo(userButton)
        }
        contentTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(userButton.snp.bottom).offset(5)
            make.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-5)
        }
        
        let replyItem = UIBarButtonItem(barButtonSystemItem: .reply,
                                        target: self,
                                        action: #selector(reply(sender:)))
        let actionItem = UIBarButtonItem(barButtonSystemItem: .action,
                                         target: self,
                                         action: #selector(action(sender:)))
        navigationItem.rightBarButtonItems = [actionItem, replyItem]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTextView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        setupUI()
        fetchData()
    }
    
    func reply(sender: UIBarButtonItem) {
        if
            let article = self.article,
            let reference = self.reference {
            let cavc = ComposeArticleController()
            cavc.boardID = reference.boardID
            cavc.replyMode = true
            cavc.originalArticle = article
            let navigationController = UINavigationController(rootViewController: cavc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true, completion: nil)
        }
    }
    
    func action(sender: UIBarButtonItem) {
        if article == nil { return }
        if let reference = self.reference {
            let acvc = ArticleContentViewController()
            acvc.articleID = reference.groupID
            acvc.boardID = reference.boardID
            var title = reference.subject
            if title.hasPrefix("Re: ") {
                title = title.substring(from: title.index(title.startIndex, offsetBy: 4))
            }
            acvc.title = title
            acvc.fromTopTen = true
            acvc.hidesBottomBarWhenPushed = true
            self.show(acvc, sender: sender)
        }
    }
    
    func preferredFontSizeChanged(notification: Notification) {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let webViewController = SFSafariViewController(url: URL)
        present(webViewController, animated: true, completion: nil)
        return false
    }
    
    private func fetchData() {
        titleLabel.text = nil
        userButton.setTitle(nil, for: .normal)
        timeLabel.text = nil
        contentTextView.text = nil
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            if let reference = self.reference {
                self.article = self.api.getArticleInBoard(boardID: reference.boardID, articleID: reference.id)
                //需要设置提醒已读
                if self.api.errorCode == 0 || self.api.errorCode == 11011 { //11011:文章不存在，已经被删除
                    let referMode: SmthAPI.ReferMode = self.replyMe ? .ReplyToMe : .AtMe
                    let result = self.api.setReferRead(mode: referMode, atPosition: reference.position)
                    print("set refer status: \(result)")
                }
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if let article = self.article {
                    if self.replyMe {
                        self.title = "\(article.authorID) 回复了我"
                    } else {
                        self.title = "\(article.authorID) @了我"
                    }
                    self.titleLabel.text = article.subject
                    self.userButton.setTitle(article.authorID, for: .normal)
                    self.timeLabel.text = article.time.shortDateString
                    self.contentTextView.attributedText = self.attributedStringFromContent(article.body)
                } else {
                    SVProgressHUD.showError(withStatus: "文章可能已被删除")
                }
            }
        }
    }
    
    private func attributedStringFromContent(_ string: String) -> NSAttributedString {
        let attributeText = NSMutableAttributedString()
        
        let normal = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body),
                      NSParagraphStyleAttributeName: NSParagraphStyle.default,
                      NSForegroundColorAttributeName: UIColor.black]
        let quoted = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .body),
                      NSParagraphStyleAttributeName: NSParagraphStyle.default,
                      NSForegroundColorAttributeName: UIColor.gray]
        
        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(": ") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }
    
}
