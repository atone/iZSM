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
import SnapKit

class ArticleContentViewController: UITableViewController {
    
    private var header: MJRefreshNormalHeader?
    private var footer: MJRefreshAutoNormalFooter?

    private let kArticleContentCellIdentifier = "ArticleContentCell"
    
    fileprivate var isScrollingStart = true // detect whether scrolling is end
    
    fileprivate var smarticles = [[SMArticle]]()
    
    fileprivate let api = SmthAPI()
    fileprivate let setting = AppSetting.sharedSetting
    
    fileprivate var totalArticleNumber: Int = 0
    fileprivate var currentForwardNumber: Int = 0
    fileprivate var currentBackwardNumber: Int = 0
    fileprivate var currentSection: Int = 0
    fileprivate var totalSection: Int {
        return Int(ceil(Double(totalArticleNumber) / Double(setting.articleCountPerSection)))
    }
    
    private var forwardThreadRange: NSRange {
        return NSMakeRange(currentForwardNumber, setting.articleCountPerSection)
    }
    private var backwardThreadRange: NSRange {
        return NSMakeRange(currentBackwardNumber - setting.articleCountPerSection,
                           setting.articleCountPerSection)
    }
    
    var boardID: String?
    var boardName: String? // if fromTopTen, this will not be set, so we must query this using api
    var articleID: Int?
    var fromTopTen: Bool = false
    var section: Int = 0 {
        didSet {
            currentSection = section
            currentForwardNumber = section * setting.articleCountPerSection
            currentBackwardNumber = section * setting.articleCountPerSection
        }
    }
    var row: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ArticleContentCell.self, forCellReuseIdentifier: kArticleContentCellIdentifier)
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        tableView.tableFooterView = footerView

        var barButtonItems = [UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(tapPageButton(sender:)))]
        if fromTopTen {
            barButtonItems.insert(UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(sender:))), at: 0)
        }
        navigationItem.rightBarButtonItems = barButtonItems
        header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(refreshAction))
        header?.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = header
        footer = MJRefreshAutoNormalFooter(refreshingTarget: self, refreshingAction: #selector(fetchMoreData))
        tableView.mj_footer = footer
        SVProgressHUD.show()
        fetchData(resetSection: false, restorePosition: true)
    }
    
    func refreshAction() {
        if currentBackwardNumber > 0 {
            fetchPrevData()
        } else {
            fetchData(resetSection: true, restorePosition: false)
        }
    }
    
    func tapPageButton(sender: UIBarButtonItem) {
        let pageListViewController = PageListViewController()
        let height = min(CGFloat(44 * totalSection), UIScreen.screenHeight() / 2)
        pageListViewController.preferredContentSize = CGSize(width: UIScreen.screenWidth() / 2, height: height)
        pageListViewController.modalPresentationStyle = .popover
        pageListViewController.currentPage = currentSection
        pageListViewController.totalPage = totalSection
        pageListViewController.delegate = self
        let presentationCtr = pageListViewController.presentationController as! UIPopoverPresentationController
        presentationCtr.barButtonItem = navigationItem.rightBarButtonItems?.last
        presentationCtr.backgroundColor = UIColor.white
        presentationCtr.delegate = self
        present(pageListViewController, animated: true, completion: nil)
    }
    
    func action(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
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
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        actionSheet.popoverPresentationController?.barButtonItem = sender
        present(actionSheet, animated: true, completion: nil)
    }
    
    func fetchData(resetSection: Bool, restorePosition: Bool) {
        self.smarticles.removeAll()
        if resetSection {
            self.currentSection = 0
            self.currentForwardNumber = 0
            self.currentBackwardNumber = 0
        }
        if let boardID = self.boardID, let articleID = self.articleID {
            networkActivityIndicatorStart()
            self.tableView.mj_footer.isHidden = true
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.forwardThreadRange,
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
                    SVProgressHUD.dismiss()
                    self.tableView.mj_footer.isHidden = false
                    if let smArticles = smArticles {
                        self.smarticles.append(smArticles)
                        self.currentForwardNumber += smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView.reloadData()
                        if restorePosition {
                            self.tableView.scrollToRow(at: IndexPath(row: self.row, section: 0),
                                                       at: .top,
                                                       animated: false)
                        } else {
                            self.tableView.scrollToTop()
                        }
                    } else {
                        SVProgressHUD.showError(withStatus: "指定的文章不存在\n或链接错误")
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            self.tableView.mj_header.endRefreshing()
            SVProgressHUD.dismiss()
        }
    }
    
    func fetchPrevData() {
        if let boardID = self.boardID, let articleID = self.articleID {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.backwardThreadRange,
                                                                  replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if let smArticles = smArticles {
                        self.smarticles.insert(smArticles, at: 0)
                        self.currentBackwardNumber -= smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView.reloadData()
                        var delayOffest = self.tableView.contentOffset
                        for i in 0..<smArticles.count {
                            delayOffest.y += self.tableView(self.tableView, heightForRowAt: IndexPath(row: i, section: 0))
                        }
                        self.tableView.setContentOffset(delayOffest, animated: false)
                        self.updateCurrentSection()
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.mj_header.endRefreshing()
                }
            }
        } else {
            tableView.mj_header.endRefreshing()
        }
    }
    
    func fetchMoreData() {
        if let boardID = self.boardID, let articleID = self.articleID {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.forwardThreadRange,
                                                                  replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()
                
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if let smArticles = smArticles {
                        self.smarticles.append(smArticles)
                        self.currentForwardNumber += smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView.reloadData()
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.mj_footer.endRefreshing()
                    if self.totalArticleNumber == self.currentForwardNumber {
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
    
    override func viewWillDisappear(_ animated: Bool) {
        let leftTopPoint = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + 64)
        if let indexPath = tableView.indexPathForRow(at: leftTopPoint) {
            ArticleReadStatusUtil.saveStatus(section: currentSection,
                                             row: indexPath.row,
                                             boardID: boardID!,
                                             articleID: articleID!)
        }
        
        super.viewWillDisappear(animated)
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
        cell.fd_enforceFrameLayout = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return articleCellAtIndexPath(indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.fd_heightForCell(withIdentifier: kArticleContentCellIdentifier, cacheBy: indexPath) { (cell) in
            if let cell = cell as? ArticleContentCell {
                self.configureArticleCell(cell: cell, atIndexPath: indexPath)
            } else {
                print("ERROR: cell is not ArticleContentCell!")
            }
        }
    }
}

extension ArticleContentViewController: PageListViewControllerDelegate {
    func pageListViewController(_ controller: PageListViewController, currentPageChangedTo currentPage: Int) {
        section = currentPage
        fetchData(resetSection: false, restorePosition: false)
        dismiss(animated: true, completion: nil)
    }
}

extension ArticleContentViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension ArticleContentViewController {
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if isScrollingStart {
                isScrollingStart = false
                updateCurrentSection()
            }
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isScrollingStart {
            isScrollingStart = false
            updateCurrentSection()
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        isScrollingStart = true
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrollingStart = true
    }
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        updateCurrentSection()
    }
    
    func updateCurrentSection() {
        let leftTopPoint = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + 64)
        if let indexPath = tableView.indexPathForRow(at: leftTopPoint) {
            let article = smarticles[indexPath.section][indexPath.row]
            currentSection = article.floor / setting.articleCountPerSection
        }
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
                        let body = "举报原因：\(textField.text!)\n\n【以下为被举报的帖子内容】\n作者：\(cell.article!.authorID)\n信区：\(cell.article!.boardID)\n标题：\(cell.article!.subject)\n时间：\(cell.article!.timeString)\n\n\(cell.article!.body)\n"
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

