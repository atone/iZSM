//
//  ArticleContentViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD
import SnapKit
import YYKit
import PullToRefreshKit

class ArticleContentViewController: NTTableViewController {

    private let kArticleContentCellIdentifier = "ArticleContentCell"
    
    private var isScrollingStart = true // detect whether scrolling is end
    private var isFetchingData = false // whether the app is fetching data
    
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
    
    weak var previewDelegate: SmthViewControllerPreviewingDelegate?
    
    override var previewActionItems: [UIPreviewActionItem] {
        if let previewDelegate = self.previewDelegate {
            return previewDelegate.previewActionItems(for: self)
        } else {
            return [UIPreviewActionItem]()
        }
    }
    
    // MARK: - ViewController Related
    override func viewDidLoad() {
        tableView.register(ArticleContentCell.self, forCellReuseIdentifier: kArticleContentCellIdentifier)
        // no use self-sizing cell
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        // set extra cells hidden
        tableView.tableFooterView = UIView()

        let barButtonItems = [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action(_:))),
                              UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(tapPageButton(_:)))]
        navigationItem.rightBarButtonItems = barButtonItems
        refreshHeader = tableView.setUpHeaderRefresh { [unowned self] in
            self.refreshAction()
        }
        refreshFooter = tableView.setUpFooterRefresh { [unowned self] in
            self.fetchMoreData()
        }
        // add double tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tableView.addGestureRecognizer(doubleTapGesture)
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        super.viewDidLoad()
        restorePosition()
        fetchData(restorePosition: true, showHUD: true)
    }
    
    deinit {
        if self.soloUser == nil { // 只看某人模式下，不保存位置
            savePosition()
        }
        api.cancel()
        networkActivityIndicatorStop(withHUD: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        if super.prefersStatusBarHidden {
            return super.prefersStatusBarHidden
        }
        return shouldHidesStatusBar
    }
    
    private func restorePosition() {
        if let boardID = self.boardID, let articleID = self.articleID,
            let result = ArticleReadStatusUtil.getStatus(boardID: boardID, articleID: articleID)
        {
            self.section = result.section
            self.row = result.row
        }
    }
    
    private func savePosition(currentRow :Int? = nil) {
        if let currentRow = currentRow {
            ArticleReadStatusUtil.saveStatus(section: currentSection,
                                             row: currentRow,
                                             boardID: boardID!,
                                             articleID: articleID!)
        } else {
            let leftTopPoint = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + 64)
            if let indexPath = tableView.indexPathForRow(at: leftTopPoint) {
                ArticleReadStatusUtil.saveStatus(section: currentSection,
                                                 row: indexPath.row,
                                                 boardID: boardID!,
                                                 articleID: articleID!)
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
                
                if self.fromTopTen && self.boardName == nil { // get boardName
                    SMBoardInfoUtil.querySMBoardInfo(for: boardID) { (board) in
                        self.boardName = board?.name
                    }
                }
                
                DispatchQueue.main.async {
                    self.isFetchingData = false
                    networkActivityIndicatorStop(withHUD: showHUD)
                    self.tableView.endHeaderRefreshing()
                    self.tableView.endFooterRefreshing()
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
            self.tableView.endHeaderRefreshing()
            self.tableView.endFooterRefreshing()
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
                    self.tableView.endHeaderRefreshing()
                    self.tableView.endFooterRefreshing()
                }
            }
        } else {
            tableView.endHeaderRefreshing()
            tableView.endFooterRefreshing()
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
                    self.tableView.endHeaderRefreshing()
                    self.tableView.endFooterRefreshing()
                    if self.totalArticleNumber == self.currentForwardNumber {
                        self.refreshFooter?.textLabel.text = "没有新帖子了"
                    } else {
                        self.refreshFooter?.textLabel.text = "上拉或点击加载更多"
                    }
                }
            }
        } else {
            tableView.endHeaderRefreshing()
            tableView.endFooterRefreshing()
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
            let openAction = UIAlertAction(title: "浏览网页版", style: .default) {[unowned self] _ in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            actionSheet.addAction(openAction)
        }
        if fromTopTen {
            if let boardID = self.boardID, let boardName = self.boardName {
                let gotoBoardAction = UIAlertAction(title: "进入 \(boardName) 版", style: .default) {[unowned self] _ in
                    let alvc = ArticleListViewController()
                    alvc.boardID = boardID
                    alvc.boardName = boardName
                    alvc.hidesBottomBarWhenPushed = true
                    self.show(alvc, sender: self)
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
        presentationCtr.backgroundColor = UIColor.white
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

extension ArticleContentViewController: UserInfoViewControllerDelegate {
    
    func userInfoViewController(_ controller: UserInfoViewController, didTapUserImageView imageView: UIImageView) {
        
    }
    
    func userInfoViewController(_ controller: UserInfoViewController, didClickSearch button: UIBarButtonItem) {
        if let userID = controller.user?.id, let boardID = controller.article?.boardID {
            dismiss(animated: true)
            SVProgressHUD.show()
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
        globalShouldRotate = false
        v?.present(fromImageView: fromView, toContainer: self.navigationController?.view, in: self, animated: true) {
            globalShouldRotate = true
        }
    }
    
    func cell(_ cell: ArticleContentCell, didClickUser sender: UIView?) {
        if let userID = cell.article?.authorID {
            networkActivityIndicatorStart()
            SMUserInfoUtil.querySMUser(for: userID) { (user) in
                networkActivityIndicatorStop()
                let userInfoVC = UserInfoViewController()
                userInfoVC.modalPresentationStyle = .popover
                userInfoVC.user = user
                userInfoVC.article = cell.article
                userInfoVC.delegate = self
                let presentationCtr = userInfoVC.presentationController as! UIPopoverPresentationController
                presentationCtr.backgroundColor = AppTheme.shared.backgroundColor
                presentationCtr.sourceView = sender
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
            let soloTitle = soloUser == nil ? "只看 \(currentUser)" : "看所有人"
            let soloAction = UIAlertAction(title: soloTitle, style: .default) { [unowned self] _ in
                self.toggleSoloMode(with: currentUser, at: currentIndexPath)
            }
            actionSheet.addAction(soloAction)
            
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
        let forwardToBoardAction = UIAlertAction(title: "转寄到版面", style: .default) { [unowned self] _ in
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
            UIApplication.shared.openURL(url)
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
        let contentWidth = view.bounds.size.width - view.layoutMargins.left - view.layoutMargins.right
        let boundingSize = CGSize(width: contentWidth, height: CGFloat.greatestFiniteMagnitude)
        // Calculate text layout
        let layout = YYTextLayout(containerSize: boundingSize, text: article.attributedBody)!
        let darkLayout = YYTextLayout(containerSize: boundingSize, text: article.attributedDarkBody)!
        // Store in dictionary
        articleContentLayout["\(article.id)_\(Int(contentWidth))"] = layout
        articleContentLayout["\(article.id)_\(Int(contentWidth))_dark"] = darkLayout
        let cacheKey = "\(article.id)_\(Int(contentWidth))" as NSString
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
                                self.toggleSoloMode(with: self.soloUser!, at: indexPath)
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
                    textField.keyboardAppearance = self.setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
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
            textField.keyboardAppearance = self.setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
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
        let resultController = BoardListSearchResultViewController.searchResultController(title: "转寄到版面") { [unowned self] (board) in
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
                        SVProgressHUD.showSuccess(withStatus: "转寄成功")
                    } else if let errorDescription = self.api.errorDescription , errorDescription != "" {
                        SVProgressHUD.showInfo(withStatus: errorDescription)
                    } else {
                        SVProgressHUD.showError(withStatus: "出错了")
                    }
                }
            }
        }
        resultController.modalPresentationStyle = .formSheet
        present(resultController, animated: true)
    }
}

extension ArticleContentViewController: UIViewControllerPreviewingDelegate, SmthViewControllerPreviewingDelegate {
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let fullscreen = FullscreenContentViewController()
        fullscreen.article = smarticles[indexPath.section][indexPath.row]
        fullscreen.previewDelegate = self
        fullscreen.modalPresentationStyle = .fullScreen
        fullscreen.modalTransitionStyle = .crossDissolve
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return fullscreen
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true)
    }
    
    func previewActionItems(for viewController: UIViewController) -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()
        if let fullscreen = viewController as? FullscreenContentViewController, let article = fullscreen.article {
            let replyAction = UIPreviewAction(title: "回复本帖", style: .default) { [unowned self] (_, _) in
                self.reply(article)
            }
            actions.append(replyAction)
            
            if let currentIndexPath = self.indexPath(for: article) {
                let currentUser = article.authorID
                let soloTitle = soloUser == nil ? "只看 \(currentUser)" : "看所有人"
                let soloAction = UIPreviewAction(title: soloTitle, style: .default) { [unowned self] (_, _) in
                    self.toggleSoloMode(with: currentUser, at: currentIndexPath)
                }
                actions.append(soloAction)
                
                if let myself = setting.username, myself.lowercased() == currentUser.lowercased() {
                    let modifyAction = UIPreviewAction(title: "修改文章", style: .default) { [unowned self] (_, _) in
                        self.modify(article, at: currentIndexPath)
                    }
                    actions.append(modifyAction)
                    let deleteAction = UIPreviewAction(title: "删除文章", style: .destructive) { [unowned self] (_, _) in
                        self.delete(article, at: currentIndexPath)
                    }
                    actions.append(deleteAction)
                }
            }
            
            let forwardToUserAction = UIPreviewAction(title: "转寄给用户", style: .default) { [unowned self] (_, _) in
                self.forward(article)
            }
            let forwardToBoardAction = UIPreviewAction(title: "转寄到版面", style: .default) { [unowned self] (_, _) in
                self.cross(article)
            }
            let reportJunkAction = UIPreviewAction(title: "举报不良内容", style: .destructive) { [unowned self] (_, _) in
                self.reportJunk(article)
            }
            let actionGroup = UIPreviewActionGroup(title: "更多…", style: .default, actions: [forwardToUserAction, forwardToBoardAction, reportJunkAction])
            actions.append(actionGroup)
        }
        return actions
    }
    
    private func indexPath(for article: SMArticle) -> IndexPath? {
        for section in 0..<smarticles.count {
            for row in 0..<smarticles[section].count {
                if smarticles[section][row].id == article.id
                    && smarticles[section][row].boardID == article.boardID {
                    return IndexPath(row: row, section: section)
                }
            }
        }
        return nil
    }
}
