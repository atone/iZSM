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
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        userButton.addTarget(self, action: #selector(clickUserButton(_:)), for: .touchUpInside)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
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
                                        action: #selector(reply(_:)))
        let actionItem = UIBarButtonItem(barButtonSystemItem: .action,
                                         target: self,
                                         action: #selector(action(_:)))
        navigationItem.rightBarButtonItems = [actionItem, replyItem]
        updateColor()
    }
    
    private func updateColor() {
        view.backgroundColor = AppTheme.shared.backgroundColor
        view.tintColor = AppTheme.shared.tintColor
        titleLabel.textColor = AppTheme.shared.textColor
        userButton.tintColor = AppTheme.shared.tintColor
        timeLabel.textColor = AppTheme.shared.lightTextColor
        contentTextView.backgroundColor = UIColor.clear
        if let body = article?.body {
            contentTextView.attributedText = attributedStringFromContent(body)
        }
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        updateColor()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentTextView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(nightModeChanged(_:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        setupUI()
        fetchData()
    }
    
    @objc private func clickUserButton(_ button: UIButton) {
        if let userID = button.titleLabel?.text {
            networkActivityIndicatorStart()
            SMUserInfoUtil.querySMUser(for: userID) { (user) in
                networkActivityIndicatorStop()
                let userInfoVC = UserInfoViewController()
                userInfoVC.modalPresentationStyle = .popover
                userInfoVC.user = user
                userInfoVC.delegate = self
                let presentationCtr = userInfoVC.presentationController as! UIPopoverPresentationController
                presentationCtr.sourceView = button
                presentationCtr.delegate = self
                self.present(userInfoVC, animated: true)
            }
        }
    }
    
    @objc private func reply(_ sender: UIBarButtonItem) {
        if
            let article = self.article,
            let reference = self.reference {
            let cavc = ComposeArticleController()
            cavc.boardID = reference.boardID
            cavc.mode = .reply
            cavc.article = article
            let navigationController = NTNavigationController(rootViewController: cavc)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        }
    }
    
    @objc private func action(_ sender: UIBarButtonItem) {
        if article == nil { return }
        if let reference = self.reference {
            let acvc = ArticleContentViewController()
            acvc.articleID = reference.groupID
            acvc.boardID = reference.boardID
            var title = reference.subject
            if title.hasPrefix("Re: ") {
                title = String(title[title.index(title.startIndex, offsetBy: 4)...])
            }
            acvc.title = title
            acvc.fromTopTen = true
            acvc.hidesBottomBarWhenPushed = true
            
            self.show(acvc, sender: sender)
        }
    }
    
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        userButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        contentTextView.font = UIFont.preferredFont(forTextStyle: .body)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let urlString = URL.absoluteString
        dPrint("Clicked: \(urlString)")
        if urlString.hasPrefix("http") {
            let webViewController = NTSafariViewController(url: URL)
            present(webViewController, animated: true)
        } else {
            UIApplication.shared.openURL(URL)
        }
        return false
    }
    
    private func fetchData() {
        titleLabel.text = nil
        userButton.setTitle(nil, for: .normal)
        timeLabel.text = nil
        contentTextView.text = nil
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            if let reference = self.reference {
                self.article = self.api.getArticleInBoard(boardID: reference.boardID, articleID: reference.id)
                //需要设置提醒已读
                if self.api.errorCode == 0 || self.api.errorCode == 11011 { //11011:文章不存在，已经被删除
                    let referMode: SmthAPI.ReferMode = self.replyMe ? .ReplyToMe : .AtMe
                    let result = self.api.setReferRead(mode: referMode, atPosition: reference.position)
                    dPrint("set refer status: \(result)")
                }
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
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
        
        let normal: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body),
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: AppTheme.shared.textColor]
        let quoted: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .body),
                                                    .paragraphStyle: NSParagraphStyle.default,
                                                    .foregroundColor: AppTheme.shared.lightTextColor]
        
        string.enumerateLines { (line, stop) -> () in
            if line.hasPrefix(":") {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: quoted))
            } else {
                attributeText.append(NSAttributedString(string: "\(line)\n", attributes: normal))
            }
        }
        return attributeText
    }
    
}

extension ReferContentViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        
    }

    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {
        if let userID = reference?.userID, let boardID = reference?.boardID {
            dismiss(animated: true)
            SMBoardInfoUtil.querySMBoardInfo(for: boardID) { (board) in
                let searchResultController = ArticleListSearchResultViewController()
                searchResultController.boardID = boardID
                searchResultController.boardName = board?.name
                searchResultController.userID = userID
                self.show(searchResultController, sender: button)
            }
        }
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem) {
        if let userID = reference?.userID {
            dismiss(animated: true)
            
            if let article = self.article { //若有文章上下文，则按照回文章格式，否则按照写信格式
                let cavc = ComposeArticleController()
                cavc.boardID = article.boardID
                cavc.article = article
                cavc.mode = .replyByMail
                let navigationController = NTNavigationController(rootViewController: cavc)
                navigationController.modalPresentationStyle = .formSheet
                present(navigationController, animated: true)
            } else {
                let cevc = ComposeEmailController()
                cevc.email = SMMail(subject: "", body: "", authorID: userID, position: 0, time: Date(), flags: "", attachments: [])
                cevc.mode = .post
                let navigationController = NTNavigationController(rootViewController: cevc)
                navigationController.modalPresentationStyle = .formSheet
                present(navigationController, animated: true)
            }
            
        }
    }
    
    func shouldEnableCompose() -> Bool {
        return true
    }
    
    func shouldEnableSearch() -> Bool {
        return true
    }
}

extension ReferContentViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
