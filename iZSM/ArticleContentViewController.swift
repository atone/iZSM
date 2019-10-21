//
//  ArticleContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD
import YYKit
import PullToRefreshKit

class ArticleContentViewController: NTTableViewController {

    private let kArticleContentCellIdentifier = "ArticleContentCell"
    
    private var isScrollingStart = true // detect whether scrolling is end
    private var isFetchingData = false // whether the app is fetching data
    
    private var indexMap = [String : IndexPath]()
    
    private var smarticles = [[SMArticle]]()
    
    var articleContentLayout = [String: YYTextLayout]()
    
    @objc dynamic var shouldHidesStatusBar: Bool = false
    
    private let api = SmthAPI()
    private let setting = AppSetting.shared
    
    private var totalArticleNumber: Int = 0
    private var currentForwardNumber: Int = 0
    private var currentBackwardNumber: Int = 0
    private var currentSection: Int = 0
    private var totalSection: Int {
        return Int(ceil(Double(totalArticleNumber) / Double(setting.articleCountPerSection)))
    }
    
    private var forwardThreadRange: NSRange {
        return NSMakeRange(currentForwardNumber, setting.articleCountPerSection)
    }
    private var backwardThreadRange: NSRange {
        return NSMakeRange(currentBackwardNumber - setting.articleCountPerSection,
                           setting.articleCountPerSection)
    }
    
    private var section: Int = 0 {
        didSet {
            currentSection = section
            currentForwardNumber = section * setting.articleCountPerSection
            currentBackwardNumber = section * setting.articleCountPerSection
        }
    }
    private var row: Int = 0
    private var soloUser: String?
    
    var boardID: String?
    var boardName: String? // if fromTopTen, this will not be set, so we must query this using api
    var articleID: Int?
    var fromTopTen: Bool = false
    var fromStar: Bool = false
    
    lazy var refreshHeader: DefaultRefreshHeader = {
        let header = DefaultRefreshHeader.header()
        header.imageRenderingWithTintColor = true
        header.tintColor = UIColor.secondaryLabel
        return header
    }()
    
    lazy var refreshFooter: DefaultRefreshFooter = {
        let footer = DefaultRefreshFooter.footer()
        footer.tintColor = UIColor.secondaryLabel
        return footer
    }()
    
    // MARK: - ViewController Related
    override func viewDidLoad() {
        tableView.register(ArticleContentCell.self, forCellReuseIdentifier: kArticleContentCellIdentifier)
        tableView.separatorStyle = .none
        // no use self-sizing cell
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        // set extra cells hidden
        tableView.tableFooterView = UIView()

        if soloUser == nil {
            let barButtonItems = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(_:))),
                                  UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(tapPageButton(_:)))]
            navigationItem.rightBarButtonItems = barButtonItems
        }
        tableView.configRefreshHeader(with: refreshHeader, container: self) { [unowned self] in
            self.refreshAction()
        }
        tableView.configRefreshFooter(with: refreshFooter, container: self) { [unowned self] in
            self.fetchMoreData()
        }
        // add double tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tableView.addGestureRecognizer(doubleTapGesture)
        super.viewDidLoad()
        if soloUser == nil {
            restorePosition()
            fetchData(restorePosition: true, showHUD: true)
        } else {
            fetchData(restorePosition: false, showHUD: true)
        }
    }
    
    deinit {
        if self.soloUser == nil { // 只看某人模式下，不保存位置
            savePosition()
        }
        api.cancel()
    }
    
    override var prefersStatusBarHidden: Bool {
        if super.prefersStatusBarHidden {
            return super.prefersStatusBarHidden
        }
        return shouldHidesStatusBar
    }
    
    private func restorePosition() {
        if let boardID = self.boardID, let articleID = self.articleID,
            let result = ArticleReadStatus.getStatus(boardID: boardID, articleID: articleID)
        {
            self.section = result.section
            self.row = result.row
        }
    }
    
    private func savePosition(currentRow :Int? = nil) {
        if let currentRow = currentRow {
            ArticleReadStatus.saveStatus(section: currentSection,
                                             row: currentRow,
                                             boardID: boardID!,
                                             articleID: articleID!)
        } else {
            if let tableView = tableView {
                let leftTopPoint = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + view.safeAreaInsets.top)
                if let indexPath = tableView.indexPathForRow(at: leftTopPoint) {
                    ArticleReadStatus.saveStatus(section: currentSection,
                                                 row: indexPath.row,
                                                 boardID: boardID!,
                                                 articleID: articleID!)
                }
            }
        }
    }
    
    // MARK: - Fetch Data
    func fetchData(restorePosition: Bool, showHUD: Bool) {
        if self.isFetchingData {
            return
        }
        if let boardID = self.boardID, let articleID = self.articleID {
            self.isFetchingData = true
            networkActivityIndicatorStart(withHUD: showHUD)
            self.refreshFooterEnabled = false
            DispatchQueue.global().async {
                var smArticles = [SMArticle]()
                if let soloUser = self.soloUser { // 只看某人模式
                    while smArticles.count < self.setting.articleCountPerSection
                        && (self.totalArticleNumber == 0 || self.currentForwardNumber < self.totalArticleNumber)
                    {
                        if let articles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                           articleID: articleID,
                                                                           threadRange: self.forwardThreadRange,
                                                                           replyMode: self.setting.sortMode)
                        {
                            smArticles += articles.filter { $0.authorID == soloUser }
                            self.currentForwardNumber += articles.count
                            self.totalArticleNumber = self.api.getLastThreadCount()
                        }
                    }
                } else {  // 正常模式
                    if let articles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                       articleID: articleID,
                                                                       threadRange: self.forwardThreadRange,
                                                                       replyMode: self.setting.sortMode)
                    {
                        smArticles += articles
                        self.currentForwardNumber += articles.count
                        self.totalArticleNumber = self.api.getLastThreadCount()
                    }
                }
                
                if (self.fromTopTen || self.fromStar) && self.boardName == nil { // get boardName
                    SMBoardInfo.querySMBoardInfo(for: boardID) { (board) in
                        self.boardName = board?.name
                    }
                }
                
                DispatchQueue.main.async {
                    self.isFetchingData = false
                    networkActivityIndicatorStop(withHUD: showHUD)
                    self.tableView.switchRefreshHeader(to: .normal(.none, 0))
                    self.tableView.switchRefreshFooter(to: .normal)
                    self.smarticles.removeAll()
                    self.articleContentLayout.removeAll()
                    self.tableView.fd_keyedHeightCache.invalidateAllHeightCache()
                    if smArticles.count > 0 {
                        self.refreshFooterEnabled = true
                        self.smarticles.append(smArticles)
                        self.tableView.reloadData()
                        if restorePosition {
                            if self.row < smArticles.count {
                                self.tableView.scrollToRow(at: IndexPath(row: self.row, section: 0),
                                                           at: .top,
                                                           animated: false)
                            } else {
                                self.tableView.scrollToRow(at: IndexPath(row: smArticles.count - 1, section: 0),
                                                           at: .top,
                                                           animated: false)
                            }
                        } else {
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                                       at: .top,
                                                       animated: false)
                        }
                    } else {
                        self.tableView.reloadData()
                        SVProgressHUD.showError(withStatus: "指定的文章不存在\n或链接错误")
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            self.tableView.switchRefreshHeader(to: .normal(.none, 0))
            self.tableView.switchRefreshFooter(to: .normal)
        }
    }
    
    func fetchPrevData() {
        if self.isFetchingData {
            return
        }
        if let boardID = self.boardID, let articleID = self.articleID {
            self.isFetchingData = true
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let smArticles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                  articleID: articleID,
                                                                  threadRange: self.backwardThreadRange,
                                                                  replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()
                
                DispatchQueue.main.async {
                    self.isFetchingData = false
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
                    self.tableView.switchRefreshHeader(to: .normal(.none, 0))
                    self.tableView.switchRefreshFooter(to: .normal)
                }
            }
        } else {
            tableView.switchRefreshHeader(to: .normal(.none, 0))
            tableView.switchRefreshFooter(to: .normal)
        }
    }
    
    @objc func fetchMoreData() {
        if self.isFetchingData {
            return
        }
        if let boardID = self.boardID, let articleID = self.articleID {
            self.isFetchingData = true
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                var smArticles = [SMArticle]()
                if let soloUser = self.soloUser { // 只看某人模式
                    while smArticles.count < self.setting.articleCountPerSection
                        && self.currentForwardNumber < self.totalArticleNumber
                    {
                        if let articles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                           articleID: articleID,
                                                                           threadRange: self.forwardThreadRange,
                                                                           replyMode: self.setting.sortMode)
                        {
                            smArticles += articles.filter { $0.authorID == soloUser }
                            self.currentForwardNumber += articles.count
                            self.totalArticleNumber = self.api.getLastThreadCount()
                        }
                    }
                } else { // 正常模式
                    if let articles = self.api.getThreadContentInBoard(boardID: boardID,
                                                                       articleID: articleID,
                                                                       threadRange: self.forwardThreadRange,
                                                                       replyMode: self.setting.sortMode)
                    {
                        smArticles += articles
                        self.currentForwardNumber += articles.count
                        self.totalArticleNumber = self.api.getLastThreadCount()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isFetchingData = false
                    networkActivityIndicatorStop()
                    if smArticles.count > 0 {
                        self.smarticles.append(smArticles)
                        self.tableView.reloadData()
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.switchRefreshHeader(to: .normal(.none, 0))
                    self.tableView.switchRefreshFooter(to: .normal)
                    if self.totalArticleNumber == self.currentForwardNumber {
                        self.refreshFooter.textLabel.text = "没有新帖子了"
                    } else {
                        self.refreshFooter.textLabel.text = "上拉或点击加载更多"
                    }
                }
            }
        } else {
            tableView.switchRefreshHeader(to: .normal(.none, 0))
            tableView.switchRefreshFooter(to: .normal)
        }
    }
    
    // MARK: - TableView Data Source and Delegate
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
        cell.setData(displayFloor: floor, smarticle: smarticle, delegate: self, controller: self)
        cell.preservesSuperviewLayoutMargins = true
        cell.fd_enforceFrameLayout = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return articleCellAtIndexPath(indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let articleId = smarticles[indexPath.section][indexPath.row].id
        let contentWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right
        let heightIdentifier = "\(articleId)_\(Int(contentWidth))" as NSString
        
        return tableView.fd_heightForCell(withIdentifier: kArticleContentCellIdentifier, cacheByKey: heightIdentifier) { (cell) in
            if let cell = cell as? ArticleContentCell {
                self.configureArticleCell(cell: cell, atIndexPath: indexPath)
            } else {
                dPrint("ERROR: cell is not ArticleContentCell!")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ArticleContentCell {
            cell.isVisible = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ArticleContentCell {
            cell.isVisible = false
        }
    }
    
    // MARK: - Actions
    @objc private func refreshAction() {
        if soloUser == nil && currentBackwardNumber > 0 {
            fetchPrevData()
        } else {
            section = 0
            fetchData(restorePosition: false, showHUD: false)
        }
    }
    
    @objc private func action(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let boardID = self.boardID, let articleID = self.articleID {
            let urlString: String
            switch self.setting.displayMode {
            case .nForum:
                urlString = "https://www.newsmth.net/nForum/#!article/\(boardID)/\(articleID)"
            case .www2:
                urlString = "https://www.newsmth.net/bbstcon.php?board=\(boardID)&gid=\(articleID)"
            case .mobile:
                urlString = "https://m.newsmth.net/article/\(boardID)/\(articleID)"
            }
            let shareAction = UIAlertAction(title: "分享本帖", style: .default) { [unowned self] _ in
                let title = "水木\(self.boardName ?? boardID)版：【\(self.title ?? "无标题")】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.barButtonItem = sender
                self.present(activityViewController, animated: true)
            }
            actionSheet.addAction(shareAction)
            if !fromStar {
                let starAction = UIAlertAction(title: "收藏本帖", style: .default) { [unowned self] _ in
                    let alertController = UIAlertController(title: "备注", message: nil, preferredStyle: .alert)
                    alertController.addTextField { textField in
                        textField.placeholder = "备注信息（可选）"
                        textField.returnKeyType = .done
                    }
                    let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alertController] _ in
                        if let textField = alertController.textFields?.first {
                            var comment: String? = nil
                            if let text = textField.text, text.count > 0 {
                                comment = text
                            }
                            networkActivityIndicatorStart(withHUD: true)
                            StarThread.updateInfo(articleID: articleID, boardID: boardID, comment: comment) { success in
                                networkActivityIndicatorStop(withHUD: true)
                                if success {
                                    SVProgressHUD.showSuccess(withStatus: "收藏成功")
                                } else {
                                    SVProgressHUD.showInfo(withStatus: "收藏失败")
                                }
                            }
                        }
                    }
                    alertController.addAction(okAction)
                    alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    self.present(alertController, animated: true)
                }
                actionSheet.addAction(starAction)
            }
            let openAction = UIAlertAction(title: "浏览网页版", style: .default) {[unowned self] _ in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            actionSheet.addAction(openAction)
        }
        if fromTopTen || fromStar {
            if let boardID = self.boardID, let boardName = self.boardName {
                let gotoBoardAction = UIAlertAction(title: "进入 \(boardName) 版", style: .default) {[unowned self] _ in
                    let alvc = ArticleListViewController()
                    alvc.boardID = boardID
                    alvc.boardName = boardName
                    alvc.hidesBottomBarWhenPushed = true
                    self.showDetailViewController(alvc, sender: self)
                }
                actionSheet.addAction(gotoBoardAction)
            }
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        actionSheet.popoverPresentationController?.barButtonItem = sender
        present(actionSheet, animated: true)
    }
    
    @objc private func tapPageButton(_ sender: UIBarButtonItem) {
        let pageListViewController = PageListViewController()
        let height = min(CGFloat(44 * totalSection), view.bounds.height / 2)
        pageListViewController.preferredContentSize = CGSize(width: 200, height: height)
        pageListViewController.modalPresentationStyle = .popover
        pageListViewController.currentPage = currentSection
        pageListViewController.totalPage = totalSection
        pageListViewController.delegate = self
        let presentationCtr = pageListViewController.presentationController as! UIPopoverPresentationController
        presentationCtr.barButtonItem = navigationItem.rightBarButtonItems?.last
        presentationCtr.delegate = self
        present(pageListViewController, animated: true)
    }
    
    @objc private func doubleTap(_ gestureRecgnizer: UITapGestureRecognizer) {
        let point = gestureRecgnizer.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: point) {
            dPrint("double tap on article content cell at \(indexPath)")
            let fullscreen = FullscreenContentViewController()
            fullscreen.article = smarticles[indexPath.section][indexPath.row]
            fullscreen.modalPresentationStyle = .fullScreen
            fullscreen.modalTransitionStyle = .crossDissolve
            present(fullscreen, animated: true)
        }
    }
}

// MARK: - Extensions for ArticleContentViewController
extension ArticleContentViewController: PageListViewControllerDelegate {
    func pageListViewController(_ controller: PageListViewController, currentPageChangedTo currentPage: Int) {
        section = currentPage
        fetchData(restorePosition: false, showHUD: true)
        dismiss(animated: true)
    }
}

extension ArticleContentViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
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
        let leftTopPoint = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + view.safeAreaInsets.top)
        if let indexPath = tableView.indexPathForRow(at: leftTopPoint) {
            let article = smarticles[indexPath.section][indexPath.row]
            currentSection = article.floor / setting.articleCountPerSection
        }
    }
}

extension ArticleContentViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {
        if let userID = controller.user?.id, let boardID = controller.article?.boardID {
            dismiss(animated: true)
            SVProgressHUD.show()
            SMBoardInfo.querySMBoardInfo(for: boardID) { (board) in
                let searchResultController = ArticleListSearchResultViewController()
                searchResultController.boardID = boardID
                searchResultController.boardName = board?.name
                searchResultController.userID = userID
                self.showDetailViewController(searchResultController, sender: button)
            }
        }
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickCompose button: UIBarButtonItem) {
        if let userID = controller.user?.id {
            dismiss(animated: true)
            
            if let article = controller.article { //若有文章上下文，则按照回文章格式，否则按照写信格式
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

extension ArticleContentViewController: ArticleContentCellDelegate {
    
    func cell(_ cell: ArticleContentCell, didClickImageAt index: Int) {
        guard let imageInfos = cell.article?.imageAtt else { return }
        guard let imageViews = cell.boxImageView?.imageViews else { return }
        var items = [YYPhotoGroupItem]()
        var fromView: UIView?
        for i in 0..<imageInfos.count {
            let imgView = imageViews[i]
            let item = YYPhotoGroupItem()
            item.thumbView = imgView
            item.largeImageURL = imageInfos[i].fullImageURL
            items.append(item)
            if i == index {
                fromView = imgView
            }
        }
        let v = YYPhotoGroupView(groupItems: items)
        globalShouldRotate = false
        v?.present(fromImageView: fromView, toContainer: self.view.window, in: self, animated: true) {
            globalShouldRotate = true
        }
    }
    
    func cell(_ cell: ArticleContentCell, didClickUser sender: UIView?) {
        if let userID = cell.article?.authorID {
            networkActivityIndicatorStart()
            SMUserInfo.querySMUser(for: userID) { (user) in
                networkActivityIndicatorStop()
                let userInfoVC = UserInfoViewController()
                userInfoVC.modalPresentationStyle = .popover
                userInfoVC.user = user
                userInfoVC.article = cell.article
                userInfoVC.delegate = self
                let presentationCtr = userInfoVC.presentationController as! UIPopoverPresentationController
                presentationCtr.sourceView = sender
                presentationCtr.sourceRect = sender!.bounds
                presentationCtr.delegate = self
                self.present(userInfoVC, animated: true)
            }
        }
        
    }
    
    func cell(_ cell: ArticleContentCell, didClickReply sender: UIView?) {
        guard let article = cell.article else { return }
        reply(article)
    }
    
    func cell(_ cell: ArticleContentCell, didClickMore sender: UIView?) {
        
        guard let article = cell.article else { return }
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        var shouldCollapse = false
        if let currentIndexPath = tableView.indexPath(for: cell) {
            let currentUser = article.authorID
            if soloUser == nil {
                let soloAction = UIAlertAction(title: "只看 \(currentUser)", style: .default) { [unowned self] _ in
                    //self.toggleSoloMode(with: currentUser, at: currentIndexPath)
                    self.showSoloMode(with: currentUser)
                }
                actionSheet.addAction(soloAction)
            }
            
            if let myself = setting.username, myself.lowercased() == currentUser.lowercased() {
                shouldCollapse = true // collapse the other actions
                let modifyAction = UIAlertAction(title: "修改文章", style: .default) { [unowned self] _ in
                    self.modify(article, at: currentIndexPath)
                }
                actionSheet.addAction(modifyAction)
                let deleteAction = UIAlertAction(title: "删除文章", style: .destructive) { [unowned self] _ in
                    self.delete(article, at: currentIndexPath)
                }
                actionSheet.addAction(deleteAction)
            }
        }
        
        let forwardAction = UIAlertAction(title: "转寄给用户", style: .default) { [unowned self] _ in
            self.forward(article)
        }
        let forwardToBoardAction = UIAlertAction(title: "转载到版面", style: .default) { [unowned self] _ in
            self.cross(article)
        }
        let reportJunkAction = UIAlertAction(title: "举报不良内容", style: .destructive) { [unowned self] _ in
            self.reportJunk(article)
        }
        
        if shouldCollapse {
            let moreAction = UIAlertAction(title: "更多…", style: .default) { [unowned self] _ in
                let moreSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                moreSheet.addAction(forwardAction)
                moreSheet.addAction(forwardToBoardAction)
                moreSheet.addAction(reportJunkAction)
                moreSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
                moreSheet.popoverPresentationController?.sourceView = sender
                moreSheet.popoverPresentationController?.sourceRect = sender!.bounds
                self.present(moreSheet, animated: true)
            }
            actionSheet.addAction(moreAction)
        } else {
            actionSheet.addAction(forwardAction)
            actionSheet.addAction(forwardToBoardAction)
            actionSheet.addAction(reportJunkAction)
        }
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender!.bounds
        present(actionSheet, animated: true)
    }
    
    func cell(_ cell: ArticleContentCell, didClick url: URL) {
        let urlString = url.absoluteString
        dPrint("Clicked: \(urlString)")
        if urlString.hasPrefix("http") {
            let webViewController = NTSafariViewController(url: url)
            present(webViewController, animated: true)
        } else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func reply(_ article: SMArticle) {
        let cavc = ComposeArticleController()
        cavc.boardID = article.boardID
        cavc.completionHandler = { [unowned self] in
            self.fetchMoreData()
        }
        cavc.mode = .reply
        cavc.article = article
        let navigationController = NTNavigationController(rootViewController: cavc)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
    private func modify(_ article: SMArticle, at indexPath: IndexPath) {
        let cavc = ComposeArticleController()
        cavc.boardID = article.boardID
        cavc.mode = .modify
        cavc.article = article
        cavc.completionHandler = { [unowned self] in
            DispatchQueue.global().async {
                if let newArticle = self.api.getArticleInBoard(boardID: article.boardID, articleID: article.id) {
                    DispatchQueue.main.async {
                        self.smarticles[indexPath.section][indexPath.row] = newArticle
                        self.forceUpdateLayout(with: newArticle)
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                    }
                }
            }
        }
        let navigationController = NTNavigationController(rootViewController: cavc)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
    private func forceUpdateLayout(with article: SMArticle) {
        let containerWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right
        articleContentLayout["\(article.id)_\(Int(containerWidth))"] = nil
        let cacheKey = "\(article.id)_\(Int(containerWidth))" as NSString
        tableView.fd_keyedHeightCache.invalidateHeight(forKey: cacheKey)
    }
    
    private func delete(_ article: SMArticle, at indexPath: IndexPath) {
        let confirmAlert = UIAlertController(title: "确定删除？", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确认", style: .destructive) { [unowned self] _ in
            networkActivityIndicatorStart(withHUD: true)
            DispatchQueue.global().async {
                let _ = self.api.deleteArticle(articleID: article.id, inBoard: article.boardID)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if self.api.errorCode == 0 {
                        SVProgressHUD.showSuccess(withStatus: "删除成功")
                        self.smarticles[indexPath.section].remove(at: indexPath.row)
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                        let totalLeftNumber = self.smarticles.reduce(0) { $0 + $1.count }
                        if totalLeftNumber == 0 {
                            if self.soloUser == nil {
                                self.navigationController?.popViewController(animated: true)
                            } else {
                                //self.toggleSoloMode(with: self.soloUser!, at: indexPath)
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    } else if self.api.errorDescription != nil && self.api.errorDescription != "" {
                        SVProgressHUD.showError(withStatus: self.api.errorDescription)
                    } else {
                        SVProgressHUD.showError(withStatus: "出错了")
                    }
                }
            }
        }
        confirmAlert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        confirmAlert.addAction(cancelAction)
        present(confirmAlert, animated: true)
    }
    
    private func toggleSoloMode(with userID: String, at indexPath: IndexPath) {
        if soloUser == nil {
            soloUser = userID
            navigationItem.rightBarButtonItems?.last?.isEnabled = false
            savePosition(currentRow: indexPath.row)
            section = 0
            fetchData(restorePosition: false, showHUD: true)
        } else {
            soloUser = nil
            navigationItem.rightBarButtonItems?.last?.isEnabled = true
            restorePosition()
            fetchData(restorePosition: true, showHUD: true)
        }
    }
    
    private func showSoloMode(with userID: String) {
        let acvc = ArticleContentViewController()
        acvc.articleID = articleID
        acvc.boardID = boardID
        acvc.boardName = boardName
        acvc.title = "只看\(userID)"
        acvc.soloUser = userID
        acvc.hidesBottomBarWhenPushed = true
        show(acvc, sender: self)
    }
    
    private func reportJunk(_ article: SMArticle) {
        var adminID = "SYSOP"
        SVProgressHUD.show()
        DispatchQueue.global().async {
            if let boards = self.api.queryBoard(query: article.boardID) {
                for board in boards {
                    if board.boardID == article.boardID {
                        let managers = board.manager.split(separator: " ")
                        if managers.count > 0 && !managers.last!.isEmpty {
                            adminID = String(managers.last!)
                        }
                        break
                    }
                }
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "举报不良内容", message: "您将要向 \(article.boardID) 版版主 \(adminID) 举报用户 \(article.authorID) 在帖子【\(article.subject)】中发表的不良内容。请您输入举报原因：", preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = "如垃圾广告、色情内容、人身攻击等"
                    textField.returnKeyType = .done
                }
                let okAction = UIAlertAction(title: "举报", style: .default) { [unowned alert, unowned self] _ in
                    if let textField = alert.textFields?.first {
                        if textField.text == nil || textField.text!.isEmpty {
                            SVProgressHUD.showInfo(withStatus: "举报原因不能为空")
                            return
                        }
                        let title = "举报用户 \(article.authorID) 在 \(article.boardID) 版中发表的不良内容"
                        let body = "举报原因：\(textField.text!)\n\n【以下为被举报的帖子内容】\n作者：\(article.authorID)\n信区：\(article.boardID)\n标题：\(article.subject)\n时间：\(article.timeString)\n\n\(article.body)\n"
                        networkActivityIndicatorStart()
                        DispatchQueue.global().async {
                            let result = self.api.sendMailTo(user: adminID, withTitle: title, content: body)
                            dPrint("send mail status: \(result)")
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
                alert.addAction(UIAlertAction(title: "取消", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }
    
    private func forward(_ article: SMArticle) {
        let alert = UIAlertController(title: "转寄文章", message: nil, preferredStyle: .alert)
        alert.addTextField{ textField in
            textField.placeholder = "收件人ID或邮箱，不填默认寄给自己"
            textField.keyboardType = UIKeyboardType.emailAddress
            textField.autocorrectionType = .no
            textField.returnKeyType = .send
        }
        let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert, unowned self] _ in
            if let textField = alert.textFields?.first {
                networkActivityIndicatorStart()
                DispatchQueue.global().async {
                    let userID = textField.text!.isEmpty ? AppSetting.shared.username! : textField.text!
                    let result = self.api.forwardArticle(articleID: article.id,
                                                         inBoard: article.boardID,
                                                         toUser: userID)
                    dPrint("forwared article status: \(result)")
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
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        self.present(alert, animated: true)
    }
    
    private func cross(_ article: SMArticle) {
        let resultController = BoardListSearchResultViewController.searchResultController(title: "转载到版面") { [unowned self] (controller, board) in
            let confirmAlert = UIAlertController(title: "确认转载?", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "确认", style: .default) { [unowned self] _ in
                self.dismiss(animated: true)
                networkActivityIndicatorStart()
                DispatchQueue.global().async {
                    let result = self.api.crossArticle(articleID: article.id,
                                                       fromBoard: article.boardID,
                                                       toBoard: board.boardID)
                    dPrint("cross article status: \(result)")
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop()
                        if self.api.errorCode == 0 {
                            SVProgressHUD.showSuccess(withStatus: "转载成功")
                        } else if let errorDescription = self.api.errorDescription , errorDescription != "" {
                            SVProgressHUD.showInfo(withStatus: errorDescription)
                        } else {
                            SVProgressHUD.showError(withStatus: "出错了")
                        }
                    }
                }
            }
            confirmAlert.addAction(okAction)
            confirmAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            controller.present(confirmAlert, animated: true)
            
        }
        resultController.modalPresentationStyle = .formSheet
        present(resultController, animated: true)
    }
}

extension ArticleContentViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let article = smarticles[indexPath.section][indexPath.row]
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        var shouldCollapse = false
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            var actionArray = [UIMenuElement]()
            let replyAction = UIAction(title: "回复本帖", image: UIImage(systemName: "arrowshape.turn.up.left")) { [unowned self] action in
                self.reply(article)
            }
            actionArray.append(replyAction)
            let currentUser = article.authorID
            if self.soloUser == nil {
                let soloAction = UIAction(title: "只看 \(currentUser)", image: UIImage(systemName: "person")) { [unowned self] action in
                    //self.toggleSoloMode(with: currentUser, at: indexPath)
                    self.showSoloMode(with: currentUser)
                }
                actionArray.append(soloAction)
            }
            if let myself = self.setting.username, myself.lowercased() == currentUser.lowercased() {
                shouldCollapse = true
                let modifyAction = UIAction(title: "修改文章", image: UIImage(systemName: "pencil")) { [unowned self] action in
                    self.modify(article, at: indexPath)
                }
                actionArray.append(modifyAction)
                let deleteAction = UIAction(title: "删除文章", image: UIImage(systemName: "trash"), attributes: .destructive) { [unowned self] action in
                    self.delete(article, at: indexPath)
                }
                actionArray.append(deleteAction)
            }
            let forwardToUserAction = UIAction(title: "转寄给用户", image: UIImage(systemName: "envelope")) { [unowned self] action in
                self.forward(article)
            }
            let forwardToBoardAction = UIAction(title: "转载到版面", image: UIImage(systemName: "text.insert")) { [unowned self] action in
                self.cross(article)
            }
            let reportJunkAction = UIAction(title: "举报不良内容", attributes: .destructive) { [unowned self] action in
                self.reportJunk(article)
            }
            if shouldCollapse {
                let moreMenu = UIMenu(title: "更多…", children: [forwardToUserAction, forwardToBoardAction, reportJunkAction])
                actionArray.append(moreMenu)
            } else {
                actionArray.append(contentsOf: [forwardToUserAction, forwardToBoardAction, reportJunkAction])
            }
            return UIMenu(title: "", children: actionArray)
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: nil, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            let article = self.smarticles[indexPath.section][indexPath.row]
            let fullscreen = self.getViewController(with: article)
            self.present(fullscreen, animated: true)
        }
    }
    
    private func getViewController(with article: SMArticle) -> FullscreenContentViewController {
        let fullscreen = FullscreenContentViewController()
        fullscreen.article = article
        fullscreen.modalPresentationStyle = .fullScreen
        fullscreen.modalTransitionStyle = .crossDissolve
        return fullscreen
    }
}

extension ArticleContentViewController: SmthContentEqutable {
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? ArticleContentViewController {
            return boardID == other.boardID && articleID == other.articleID && soloUser == other.soloUser
        }
        return false
    }
}

