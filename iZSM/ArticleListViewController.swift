//
//  ArticleListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD
import SmthConnection

class ArticleListViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate, FavoriteAddable {
    
    private let kArticleListCellIdentifier = "ArticleListCell"
    var boardID: String?
    var boardName: String? {
        didSet { title = boardName }
    }
    var boardManagers: [String]?
    
    private var indexMap = [String : IndexPath]()
    
    var threadSortMode = AppSetting.shared.threadSortMode {
        didSet {
            AppSetting.shared.threadSortMode = threadSortMode
        }
    }
    
    var currentPage = 0 // for origin mode
    
    var totalThreads = 0
    var threadCursor = 0
    private var threadRange: NSRange {
        switch threadSortMode {
        case .byPostNewFirst, .byReplyNewFirst:
            return NSMakeRange(threadCursor, setting.threadCountPerSection)
        case .byPostOldFirst, .byReplyOldFirst:
            return NSMakeRange(threadCursor - setting.threadCountPerSection, setting.threadCountPerSection)
        }
    }
    private var searchRange: NSRange {
        return NSMakeRange(threadCursor, setting.threadCountPerSection)
    }
    var threads: [[SMThread]] = [[SMThread]]() {
        didSet { tableView?.reloadData() }
    }
    
    var originalThreadCursor: Int? = nil
    var originalThread: [[SMThread]]?
    var searchMode = false {
        didSet {
            self.fd_interactivePopDisabled = searchMode // not allow swipe to pop when in search mode
        }
    }
    
    var searchString: String? {
        return searchController?.searchBar.text
    }
    var selectedIndex: Int = 0
    
    private var searchController: UISearchController?
    
    func didDismissSearchController(_ searchController: UISearchController) {
        searchMode = false
        refreshHeaderEnabled = true
        threads = originalThread!
        threadCursor = originalThreadCursor!
        originalThread = nil
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchMode = true
        refreshHeaderEnabled = false
        originalThread = threads
        originalThreadCursor = threadCursor
        threads = [[SMThread]]()
        threadCursor = 0
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(forText: searchString, scope: selectedIndex)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        if selectedScope != selectedIndex {
            selectedIndex = selectedScope
            search(forText: searchBar.text, scope: selectedScope)
        }
    }
    
    func search(forText searchString: String?, scope: Int) {
        if let boardID = self.boardID, let searchString = searchString, !searchString.isEmpty {
            self.threadCursor = 0
            let currentMode = searchMode
            let completion: SmthCompletion<[SMThread]> = { result in
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if currentMode != self.searchMode { return } //模式已经改变，则丢弃数据
                    self.threads.removeAll()
                    switch result {
                    case .success(let threads):
                        if threads.count > 0 {
                            self.threads.append(threads)
                            self.threadCursor += threads.count
                        }
                    case .failure(let error):
                        error.display()
                    }
                }
            }
            networkActivityIndicatorStart(withHUD: true)
            if scope == 0 {
                api.searchArticle(title: searchString, in: boardID, range: searchRange, completion: completion)
            } else if scope == 1 {
                api.searchArticle(user: searchString, in: boardID, range: searchRange, completion: completion)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ArticleListViewCell.self, forCellReuseIdentifier: kArticleListCellIdentifier)
        
        // search related
        searchController = UISearchController(searchResultsController: nil)
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        searchController?.searchBar.scopeButtonTitles = ["标题关键字", "同作者"]
        searchController?.searchBar.selectedScopeButtonIndex = 0
        navigationItem.searchController = searchController
        navigationItem.scrollEdgeAppearance = UINavigationBarAppearance() // fix transparent search bar
        
        let composeButton = UIBarButtonItem(barButtonSystemItem: .compose,
                                            target: self,
                                            action: #selector(composeArticle(_:)))
        let sortModButton = UIBarButtonItem(barButtonSystemItem: .action,
                                            target: self,
                                            action: #selector(tapActionButton(_:)))
        navigationItem.rightBarButtonItems =  [composeButton, sortModButton]
        if let boardID = boardID {
            SMBoardInfo.hit(for: boardID)
        }
    }
    
    override func clearContent() {
        threads.removeAll()
    }
    
    // MARK: - Blacklist
    private var blackUserSet = Set<String>()
    private var blackKeywordList = [String]()
    
    private func isGoodTitle(_ title: String) -> Bool {
        return blackKeywordList.allSatisfy {
            !title.lowercased().contains($0)
        }
    }
    
    private func isGoodUser(_ user: String) -> Bool {
        return !blackUserSet.contains(user.lowercased())
    }
    
    private func updateBlacklist() {
        blackUserSet = Set(setting.userBlacklist.map{$0.lowercased().trimmingCharacters(in: .whitespaces)})
        blackKeywordList = setting.keywordBlacklist.map{$0.lowercased().trimmingCharacters(in: .whitespaces)}
    }
    
    // MARK: - Fetch Data
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            let currentThreadSortMode = self.threadSortMode
            updateBlacklist()
            networkActivityIndicatorStart(withHUD: showHUD)
            DispatchQueue.global().async {
                do {
                    if self.boardManagers == nil {
                        let board = try self.api.getBoard(id: boardID)
                        self.boardManagers = board.manager.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    }
                    
                    var threadSection = [SMThread]()
                    switch self.threadSortMode {
                    case .byReplyNewFirst:
                        self.threadCursor = 0
                        while threadSection.count == 0 {
                            var threads = try self.api.getThreadList(in: boardID, range: self.threadRange)
                            // self.threadCursor存储的是已经加载的主题数（包括被过滤掉的）
                            self.threadCursor += threads.count
                            if self.setting.hideAlwaysOnTopThread {
                                // 过滤置顶帖
                                threads = threads.filter {
                                    !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                                }
                            }
                            // 过滤黑名单
                            threads = threads.filter {
                                self.isGoodTitle($0.subject) && self.isGoodUser($0.authorID)
                            }
                            threadSection.append(contentsOf: threads)
                        }
                    case .byReplyOldFirst:
                        self.totalThreads = try self.api.getThreadCount(in: boardID)
                        guard self.totalThreads > 0 else { break }
                        self.threadCursor = self.totalThreads
                        while threadSection.count == 0 {
                            var threads = try self.api.getThreadList(in: boardID, range: self.threadRange)
                            // self.threadCursor存储的是已经加载的主题数（包括被过滤掉的）
                            self.threadCursor -= threads.count
                            if self.setting.hideAlwaysOnTopThread {
                                // 过滤置顶帖
                                threads = threads.filter {
                                    !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                                }
                            }
                            // 过滤黑名单
                            threads = threads.filter {
                                self.isGoodTitle($0.subject) && self.isGoodUser($0.authorID)
                            }
                            threadSection.append(contentsOf: threads.reversed())
                        }
                    case .byPostNewFirst:
                        self.currentPage = -1
                        while threadSection.count == 0 {
                            let result = self.api.getOriginThreadList(for: boardID, page: self.currentPage)
                            if result.page == 0 || result.page == -2 {
                                break // unrecoverable error
                            } else if result.page == -1 { // decode error
                                if self.currentPage == -1 {
                                    break // cannot recover from error since page is unknown
                                } else {
                                    self.currentPage -= 1
                                    continue // try to load next page
                                }
                            }
                            self.currentPage = result.page - 1
                            var threads = result.threads
                            if self.setting.hideAlwaysOnTopThread {
                                // 过滤置顶帖
                                threads = threads.filter {
                                    !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                                }
                            }
                            // 过滤黑名单
                            threads = threads.filter {
                                self.isGoodTitle($0.subject) && self.isGoodUser($0.authorID)
                            }
                            threadSection.append(contentsOf: threads.reversed())
                        }
                    case .byPostOldFirst:
                        self.currentPage = 1
                        while threadSection.count == 0 {
                            let result = self.api.getOriginThreadList(for: boardID, page: self.currentPage)
                            if result.page == 0 || result.page == -2 {
                                break // unrecoverable error
                            } else if result.page == -1 { // decode error
                                self.currentPage += 1
                                continue // try to load next page
                            }
                            self.currentPage = result.page + 1
                            var threads = result.threads
                            if self.setting.hideAlwaysOnTopThread {
                                // 过滤置顶帖
                                threads = threads.filter {
                                    !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                                }
                            }
                            // 过滤黑名单
                            threads = threads.filter {
                                self.isGoodTitle($0.subject) && self.isGoodUser($0.authorID)
                            }
                            threadSection.append(contentsOf: threads)
                        }
                    }
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop(withHUD: showHUD)
                        completion?()
                        if currentMode != self.searchMode || currentThreadSortMode != self.threadSortMode { return } //如果模式已经被切换，则数据丢弃
                        self.threads.removeAll()
                        if threadSection.count > 0 {
                            self.threads.append(threadSection)
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop(withHUD: showHUD)
                        completion?()
                        self.threads.removeAll()
                        (error as? SMError)?.display()
                    }
                }
            }
        } else {
            completion?()
        }
    }
    
    private var _isFetchingMoreData = false
    private var _semaphore = DispatchSemaphore(value: 1)
    
    override func fetchMoreData() {
        if let boardID = self.boardID {
            
            _semaphore.wait()
            if !_isFetchingMoreData {
                _isFetchingMoreData = true
                _semaphore.signal()
            } else {
                _semaphore.signal()
                return
            }
            
            guard let searchString = self.searchString else { return }
            let currentMode = self.searchMode
            let currentThreadSortMode = self.threadSortMode
            updateBlacklist()
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                do {
                    var threadSection = [SMThread]()
                    if self.searchMode {
                        if self.selectedIndex == 0 {
                            let threads = try self.api.searchArticle(title: searchString, in: boardID, range: self.searchRange)
                            threadSection.append(contentsOf: threads)
                        } else if self.selectedIndex == 1 {
                            let threads = try self.api.searchArticle(user: searchString, in: boardID, range: self.searchRange)
                            threadSection.append(contentsOf: threads)
                        }
                        self.threadCursor += threadSection.count
                    } else {
                        switch self.threadSortMode {
                        case .byReplyNewFirst:
                            let threads = try self.api.getThreadList(in: boardID, range: self.threadRange)
                            threadSection.append(contentsOf: threads)
                            self.threadCursor += threadSection.count
                        case .byReplyOldFirst:
                            let threads = try self.api.getThreadList(in: boardID, range: self.threadRange)
                            threadSection.append(contentsOf: threads)
                            self.threadCursor -= threadSection.count
                        case .byPostNewFirst:
                            var lastPage = -1 // decode error
                            while lastPage == -1, threadSection.count == 0 {
                                let result = self.api.getOriginThreadList(for: boardID, page: self.currentPage)
                                if result.page == 0 || result.page == -2 { break } // unrecoverable error
                                threadSection.append(contentsOf: result.threads.reversed())
                                lastPage = result.page
                                self.currentPage -= 1
                            }
                        case .byPostOldFirst:
                            var lastPage = -1
                            while lastPage == -1, threadSection.count == 0 {
                                let result = self.api.getOriginThreadList(for: boardID, page: self.currentPage)
                                if result.page == 0 || result.page == -2 { break } // unrecoverable error
                                threadSection.append(contentsOf: result.threads)
                                lastPage = result.page
                                self.currentPage += 1
                            }
                        }
                    }
                    // 过滤置顶帖
                    if self.setting.hideAlwaysOnTopThread {
                        threadSection = threadSection.filter {
                            !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                        }
                    }
                    // 过滤掉重复的帖子
                    let loadedThreadIds = self.threads.reduce(Set<Int>()) {
                        $0.union(Set($1.map { $0.id }))
                    }
                    threadSection = threadSection.filter {
                        !loadedThreadIds.contains($0.id)
                    }
                    // 过滤黑名单
                    threadSection = threadSection.filter {
                        self.isGoodTitle($0.subject) && self.isGoodUser($0.authorID)
                    }
                    DispatchQueue.main.async {
                        self._isFetchingMoreData = false
                        networkActivityIndicatorStop()
                        if self.searchMode != currentMode || self.threadSortMode != currentThreadSortMode {
                            return //如果模式已经改变，则此数据需要丢弃
                        }
                        if threadSection.count > 0 {
                            let indexPath = self.tableView.indexPathForSelectedRow
                            self.threads.append(threadSection)
                            if let indexPath = indexPath {
                                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        self._isFetchingMoreData = false
                        networkActivityIndicatorStop()
                        (error as? SMError)?.display()
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return threads.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads[section].count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if threads.isEmpty {
            return
        }
        if indexPath.section == threads.count - 1 && indexPath.row == threads[indexPath.section].count / 3 * 2 {
            fetchMoreData()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kArticleListCellIdentifier, for: indexPath) as! ArticleListViewCell
        cell.thread = threads[indexPath.section][indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acvc = ArticleContentViewController()
        let thread = threads[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = boardID
        acvc.boardName = boardName
        acvc.title = thread.subject
        acvc.hidesBottomBarWhenPushed = true
        if thread.flags.hasPrefix("*") {
            var readThread = thread
            let flags = thread.flags
            readThread.flags = " " + flags[flags.index(after: flags.startIndex)...]
            threads[indexPath.section][indexPath.row] = readThread
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) // restore selection
        }
        
        showDetailViewController(acvc, sender: self)
    }
    
    @objc private func composeArticle(_ sender: Any?) {
        let cavc = ComposeArticleController()
        cavc.boardID = boardID
        cavc.completionHandler = { [unowned self] in
            self.fetchDataDirectly(showHUD: false)
        }
        let nvc = NTNavigationController(rootViewController: cavc)
        nvc.modalPresentationStyle = .formSheet
        present(nvc, animated: true)
    }
    
    @objc private func tapActionButton(_ sender: UIBarButtonItem) {
        let articleListActionVC = ArticleListActionViewController()
        let height: CGFloat
        if let bms = boardManagers, bms.count > 0 {
            height = min(310 + 44 * CGFloat(bms.count), view.bounds.height / 2)
        } else {
            height = min(280, view.bounds.height / 2) // 280 = 30 * 2 + 44 * 5
        }
        articleListActionVC.preferredContentSize = CGSize(width: 240, height: height)
        articleListActionVC.modalPresentationStyle = .popover
        
        articleListActionVC.threadSortMode = threadSortMode
        articleListActionVC.threadSortModeHandler = { [unowned self] newThreadSortMode in
            if self.threadSortMode != newThreadSortMode {
                self.threadSortMode = newThreadSortMode
                self.fetchData(showHUD: true)
            }
            self.dismiss(animated: true)
        }
        
        articleListActionVC.boardManagers = self.boardManagers ?? []
        articleListActionVC.sendMessageHandler = { [unowned self] manager in
            self.dismiss(animated: true)
            let cevc = ComposeEmailController()
            cevc.email = Mail(subject: "", body: "", authorID: manager)
            cevc.mode = .post
            let navigationController = NTNavigationController(rootViewController: cevc)
            navigationController.modalPresentationStyle = .formSheet
            self.present(navigationController, animated: true)
        }
        
        articleListActionVC.favoriteHandler = { [unowned self] index in
            self.dismiss(animated: true)
            guard let boardID = self.boardID else { return }
            self.addFavoriteWithBoardID(boardID, in: 0)
        }
        
        let presentationCtr = articleListActionVC.presentationController as! UIPopoverPresentationController
        presentationCtr.barButtonItem = navigationItem.rightBarButtonItems?.last
        presentationCtr.delegate = self
        present(articleListActionVC, animated: true)
    }
}

extension ArticleListViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !setting.disableHapticTouch else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let thread = threads[indexPath.section][indexPath.row]
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let urlString: String
        switch self.setting.displayMode {
        case .nForum:
            urlString = setting.httpPrefix + "www.mysmth.net/nForum/#!article/\(thread.boardID)/\(thread.id)"
        case .www2:
            urlString = setting.httpPrefix + "www.mysmth.net/bbstcon.php?board=\(thread.boardID)&gid=\(thread.id)"
        case .mobile:
            urlString = setting.httpPrefix + "m.mysmth.net/article/\(thread.boardID)/\(thread.id)"
        }
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: thread)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            let openAction = UIAction(title: "浏览网页版", image: UIImage(systemName: "safari")) { [unowned self] action in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            let starAction = UIAction(title: "收藏本帖", image: UIImage(systemName: "star")) { [unowned self] action in
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
                        StarThread.updateInfo(articleID: thread.id, boardID: thread.boardID, comment: comment) { success in
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
            let shareAction = UIAction(title: "分享本帖", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] action in
                let title = "水木\(thread.boardName)版：【\(thread.subject)】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = cell
                activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                self.present(activityViewController, animated: true)
            }
            return UIMenu(title: "", children: [openAction, starAction, shareAction])
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            let thread = self.threads[indexPath.section][indexPath.row]
            if thread.flags.hasPrefix("*") {
                var readThread = thread
                let flags = thread.flags
                readThread.flags = " " + flags.dropFirst()
                self.threads[indexPath.section][indexPath.row] = readThread
            }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            let acvc = self.getViewController(with: thread)
            self.showDetailViewController(acvc, sender: self)
        }
    }
    
    private func getViewController(with thread: SMThread) -> ArticleContentViewController {
        let acvc = ArticleContentViewController()
        acvc.articleID = thread.id
        acvc.boardID = boardID
        acvc.boardName = boardName
        acvc.title = thread.subject
        acvc.hidesBottomBarWhenPushed = true
        return acvc
    }
}

extension ArticleListViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

class ArticleListActionViewController: UITableViewController {
    var threadSortMode = AppSetting.shared.threadSortMode
    var threadSortModeHandler: ((AppSetting.ThreadSortMode) -> Void)?
    var boardManagers = [String]()
    var sendMessageHandler: ((String) -> Void)?
    var favoriteHandler: ((Int) -> Void)?
    
    private let kCellIdentifier = "ArticleListActionCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.reloadData()
        
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        var number = 1
        if boardManagers.count > 0 {
            number += 1
        }
        if favoriteHandler != nil {
            number += 1
        }
        return number
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4 // sort mode
        } else if section == 1 {
            return boardManagers.count // send message to board managers
        } else {
            return 1 // favorite actions
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "帖子排序"
        case 1:
            return "联系版主"
        case 2:
            return "收藏操作"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: kCellIdentifier)
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "回复时间，最新在前"
            case 1:
                cell.textLabel?.text = "回复时间，最早在前"
            case 2:
                cell.textLabel?.text = "发帖时间，最新在前"
            case 3:
                cell.textLabel?.text = "发帖时间，最早在前"
            default:
                cell.textLabel?.text = nil
            }
            if indexPath.row == threadSortMode.rawValue {
                cell.detailTextLabel?.text = "✓"
                cell.detailTextLabel?.textColor = UIColor(named: "SmthColor")
            }
        } else if indexPath.section == 1 {
            cell.textLabel?.text = "寄信给 \(boardManagers[indexPath.row])"
        } else {
            cell.textLabel?.text = "收藏本版"
            cell.accessoryView = UIImageView(image: UIImage(systemName: "star.fill"))
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let newSortMode = AppSetting.ThreadSortMode(rawValue: indexPath.row) {
                threadSortMode = newSortMode
                tableView.reloadData()
                threadSortModeHandler?(newSortMode)
            } else {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        } else if indexPath.section == 1 {
            sendMessageHandler?(boardManagers[indexPath.row])
        } else {
            favoriteHandler?(indexPath.row)
        }
    }
}

extension ArticleListViewController {
    func navigateCompose() {
        composeArticle(nil)
    }
    
    func navigateRefresh() {
        fetchDataDirectly(showHUD: true) {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
    
    func navigateEnterSearch() {
        searchController?.isActive = true
        searchController?.searchBar.becomeFirstResponder()
    }
    
    func navigateEscapeSearch() {
        searchController?.isActive = false
    }
}
