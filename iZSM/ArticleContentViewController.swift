//
//  ArticleContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices
import SVProgressHUD

class ArticleContentViewController: UITableViewController {
    
    private var header: MJRefreshNormalHeader?
    private var footer: MJRefreshAutoNormalFooter?

    private let kArticleContentCellIdentifier = "ArticleContentCell"
    
    private var smarticles = [[SMArticle]]()
    
    fileprivate let api = SmthAPI()
    private let setting = AppSetting.sharedSetting
    
    private var totalArticleNumber: Int = 0
    private var currentArticleNumber: Int = 0
    
    private var threadRange: NSRange {
        return NSMakeRange(currentArticleNumber, setting.articleCountPerSection)
    }
    
    var boardID: String?
    var boardName: String? // if fromTopTen, this will not be set, so we must query this using api
    var articleID: Int?
    var fromTopTen: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ArticleContentCell.self, forCellReuseIdentifier: kArticleContentCellIdentifier)
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        tableView.tableFooterView = footerView
        
        tableView.estimatedRowHeight = 88
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                            target: self,
                                                            action: #selector(reverse(sender:)))
        header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(fetchDataDirectly))
        header?.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = header
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(fetchMoreData))
        tableView.mj_footer = footer
        fetchData()
    }
    
    func reverse(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        switch setting.sortMode {
        case .LaterPostFirst:
            let action = UIAlertAction(title: "最早回复在前", style: .default) { [unowned self] action in
                self.setting.sortMode = .Normal
                self.fetchData()
            }
            actionSheet.addAction(action)
        case .Normal:
            let action = UIAlertAction(title: "最新回复在前", style: .default) { [unowned self] action in
                self.setting.sortMode = .LaterPostFirst
                self.fetchData()
            }
            actionSheet.addAction(action)
        }
        if fromTopTen {
            if let boardID = self.boardID, let boardName = self.boardName {
                let gotoBoardAction = UIAlertAction(title: "进入 \(boardName) 版", style: .default) {[unowned self] action in
                    let alvc = ArticleListViewController()
                    alvc.boardID = boardID
                    alvc.boardName = boardName
                    alvc.hidesBottomBarWhenPushed = true
                    self.show(alvc, sender: self)
                }
                actionSheet.addAction(gotoBoardAction)
            }
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        actionSheet.popoverPresentationController?.barButtonItem = sender
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    func fetchDataDirectly() {
        self.smarticles.removeAll()
        self.currentArticleNumber = 0
        if let boardID = self.boardID, let articleID = self.articleID {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.threadRange,
                                                                  replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()
                
                if self.fromTopTen && self.boardName == nil { // get boardName
                    if let boards = self.api.queryBoard(query: boardID) {
                        for board in boards {
                            if board.boardID == boardID {
                                self.boardName = board.name
                                break
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    self.tableView.mj_header.endRefreshing()
                    self.tableView.mj_footer.isHidden = false
                    if let smArticles = smArticles {
                        self.smarticles.append(smArticles)
                        self.currentArticleNumber += smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView?.reloadData()
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            self.tableView.mj_header.endRefreshing()
            tableView.mj_footer.isHidden = false
        }
    }
    
    func fetchData() {
        tableView.mj_header.beginRefreshing()
        tableView.mj_footer.isHidden = true
    }
    
    func fetchMoreData() {
        if let boardID = self.boardID, let articleID = self.articleID {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.threadRange,
                                                                  replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if let smArticles = smArticles {
                        let newIndexSet = IndexSet(integer: self.smarticles.count)
                        self.smarticles.append(smArticles)
                        self.currentArticleNumber += smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView.insertSections(newIndexSet, with: .none)
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.mj_footer.endRefreshing()
                    if self.totalArticleNumber == self.currentArticleNumber {
                        self.footer?.setTitle("没有新帖子了", for: MJRefreshState.idle)
                    }else {
                        self.footer?.setTitle("点击或上拉加载更多", for: MJRefreshState.idle)
                    }
                }
            }
        } else {
            tableView.mj_footer.endRefreshing()
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return smarticles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smarticles[section].count
    }
    
    private func articleCellAtIndexPath(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kArticleContentCellIdentifier, for: indexPath) as! ArticleContentCell
        configureArticleCell(cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    private func configureArticleCell(cell: ArticleContentCell, atIndexPath indexPath: IndexPath) {
        let smarticle = smarticles[indexPath.section][indexPath.row]
        var floor = smarticle.floor
        if setting.sortMode == .LaterPostFirst && floor != 0 {
            floor = totalArticleNumber - floor
        }
        cell.setData(displayFloor: floor, smarticle: smarticle, delegate: self)
        cell.preservesSuperviewLayoutMargins = false
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return articleCellAtIndexPath(indexPath: indexPath)
    }
}

extension ArticleContentViewController: ArticleContentCellDelegate {
    
    func cell(_ cell: ArticleContentCell, didClickImageAt index: Int) {
        guard let imageInfos = cell.article?.imageAtt else { return }
        var items = [YYPhotoGroupItem]()
        var fromView: UIView?
        for i in 0..<imageInfos.count {
            let imgView = cell.imageViews[i]
            let item = YYPhotoGroupItem()
            item.thumbView = imgView
            item.largeImageURL = imageInfos[i].fullImageURL
            items.append(item)
            if i == index {
                fromView = imgView
            }
        }
        let v = YYPhotoGroupView(groupItems: items)
        v?.present(fromImageView: fromView, toContainer: self.navigationController?.view, animated: true, completion: nil)
    }
    
    func cell(_ cell: ArticleContentCell, didClickReply button: UIButton) {
        reply(ByMail: false, in: cell)
    }
    
    func cell(_ cell: ArticleContentCell, didClickMore button: UIButton) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyArticleAction = UIAlertAction(title: "复制文章", style: .default) { action in
            UIPasteboard.general.string = cell.article!.body
            SVProgressHUD.showSuccess(withStatus: "复制成功")
        }
        actionSheet.addAction(copyArticleAction)
        let replyByMailAction = UIAlertAction(title: "私信回复", style: .default) { action in
            self.reply(ByMail: true, in: cell)
        }
        actionSheet.addAction(replyByMailAction)
        let forwardAction = UIAlertAction(title: "转寄给用户", style: .default) { action in
            self.forward(ToBoard: false, in: cell)
        }
        actionSheet.addAction(forwardAction)
        let forwardToBoardAction = UIAlertAction(title: "转寄到版面", style: .default) { action in
            self.forward(ToBoard: true, in: cell)
        }
        actionSheet.addAction(forwardToBoardAction)
        let reportJunkAction = UIAlertAction(title: "举报不良内容", style: .destructive) { action in
            self.reportJunk(in: cell)
        }
        actionSheet.addAction(reportJunkAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        actionSheet.popoverPresentationController?.sourceView = button
        actionSheet.popoverPresentationController?.sourceRect = button.bounds
        present(actionSheet, animated: true, completion: nil)
    }
    
    func cell(_ cell: ArticleContentCell, didClick url: URL) {
        let urlString = url.absoluteString
        print("Clicked: \(urlString)")
        if urlString.hasPrefix("http") {
            let webViewController = SFSafariViewController(url: url)
            present(webViewController, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    private func reply(ByMail: Bool, in cell: ArticleContentCell) {
        let cavc = ComposeArticleController()
        cavc.boardID = cell.article?.boardID
        cavc.delegate = self
        cavc.replyMode = true
        cavc.originalArticle = cell.article
        cavc.replyByMail = ByMail
        let navigationController = UINavigationController(rootViewController: cavc)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true, completion: nil)
    }
    
    private func reportJunk(in cell: ArticleContentCell) {
        var adminID = "SYSOP"
        SVProgressHUD.show()
        DispatchQueue.global().async {
            if let boardID = cell.article?.boardID, let boards = self.api.queryBoard(query: boardID) {
                for board in boards {
                    if board.boardID == boardID {
                        let managers = board.manager.characters.split { $0 == " " }.map { String($0) }
                        if managers.count > 0 && !managers[0].isEmpty {
                            adminID = managers[0]
                        }
                        break
                    }
                }
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "举报不良内容", message: "您将要向 \(cell.article!.boardID) 版版主 \(adminID) 举报用户 \(cell.article!.authorID) 在帖子【\(cell.article!.subject)】中发表的不良内容。请您输入举报原因：", preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = "如垃圾广告、色情内容、人身攻击等"
                    textField.returnKeyType = .done
                }
                let okAction = UIAlertAction(title: "举报", style: .default) { [unowned alert, unowned self] action in
                    if let textField = alert.textFields?.first {
                        if textField.text == nil || textField.text!.isEmpty {
                            SVProgressHUD.showInfo(withStatus: "举报原因不能为空")
                            return
                        }
                        let title = "举报用户 \(cell.article!.authorID) 在 \(cell.article!.boardID) 版中发表的不良内容"
                        let body = "举报原因：\(textField.text)\n\n【以下为被举报的帖子内容】\n作者：\(cell.article!.authorID)\n信区：\(cell.article!.boardID)\n标题：\(cell.article!.subject)\n时间：\(cell.article!.timeString)\n\n\(cell.article!.body)\n"
                        networkActivityIndicatorStart()
                        DispatchQueue.global().async {
                            let result = self.api.sendMailTo(user: adminID, withTitle: title, content: body)
                            print("send mail status: \(result)")
                            DispatchQueue.main.async {
                                networkActivityIndicatorStop()
                                if self.api.errorCode == 0 {
                                    SVProgressHUD.showSuccess(withStatus: "举报成功")
                                } else if let errorDescription = self.api.errorDescription, errorDescription != "" {
                                    SVProgressHUD.showInfo(withStatus: errorDescription)
                                } else {
                                    SVProgressHUD.showError(withStatus: "出错了")
                                }
                            }
                        }
                    }
                }
                alert.addAction(okAction)
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func forward(ToBoard: Bool, in cell: ArticleContentCell) {
        if let originalArticle = cell.article {
            let api = SmthAPI()
            let alert = UIAlertController(title: (ToBoard ? "转寄到版面":"转寄给用户"), message: nil, preferredStyle: .alert)
            alert.addTextField{ textField in
                textField.placeholder = ToBoard ? "版面ID" : "收件人，不填默认寄给自己"
                textField.keyboardType = ToBoard ? UIKeyboardType.asciiCapable : UIKeyboardType.emailAddress
                textField.autocorrectionType = .no
                textField.returnKeyType = .send
            }
            let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert, unowned self] action in
                if let textField = alert.textFields?.first {
                    networkActivityIndicatorStart()
                    DispatchQueue.global().async {
                        if ToBoard {
                            let result = api.crossArticle(articleID: originalArticle.id,
                                                          fromBoard: cell.article!.boardID,
                                                          toBoard: textField.text!)
                            print("cross article status: \(result)")
                        } else {
                            let user = textField.text!.isEmpty ? AppSetting.sharedSetting.username! : textField.text!
                            let result = api.forwardArticle(articleID: originalArticle.id,
                                                            inBoard: cell.article!.boardID,
                                                            toUser: user)
                            print("forwared article status: \(result)")
                        }
                        DispatchQueue.main.async {
                            networkActivityIndicatorStop()
                            if self.api.errorCode == 0 {
                                SVProgressHUD.showSuccess(withStatus: "转寄成功")
                            } else if let errorDescription = self.api.errorDescription , errorDescription != "" {
                                SVProgressHUD.showInfo(withStatus: errorDescription)
                            } else {
                                SVProgressHUD.showError(withStatus: "出错了")
                            }
                        }
                    }
                }
            }
            alert.addAction(okAction)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ArticleContentViewController: ComposeArticleControllerDelegate {
    // ComposeArticleControllerDelegate
    func articleDidPosted() {
        fetchMoreData()
    }
}

