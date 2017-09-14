//
//  ArticleListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class ArticleListViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate {
    
    private let kArticleListCellIdentifier = "ArticleListCell"
    var boardID: String?
    var boardName: String? {
        didSet { title = boardName }
    }
    
    weak var previewDelegate: SmthViewControllerPreviewingDelegate?
    
    override var previewActionItems: [UIPreviewActionItem] {
        if let previewDelegate = self.previewDelegate {
            return previewDelegate.previewActionItems(for: self)
        } else {
            return [UIPreviewActionItem]()
        }
    }
    
    var threadLoaded = 0
    private var threadRange: NSRange {
        return NSMakeRange(threadLoaded, setting.threadCountPerSection)
    }
    var threads: [[SMThread]] = [[SMThread]]() {
        didSet { tableView?.reloadData() }
    }
    
    var originalThreadLoaded: Int? = nil
    var originalThread: [[SMThread]]?
    var searchMode = false {
        didSet {
            self.fd_interactivePopDisabled = searchMode // not allow swipe to pop when in search mode
        }
    }
    
    var searchString: String? {
        return searchController?.searchBar.text
    }
    var selectedIndex: Int {
        return searchController?.searchBar.selectedScopeButtonIndex ?? 0
    }
    
    private var searchController: UISearchController?
    
    func didDismissSearchController(_ searchController: UISearchController) {
        tableView.tableHeaderView = nil
        searchMode = false
        api.cancel()
        tableView.mj_header.isHidden = false
        threads = originalThread!
        threadLoaded = originalThreadLoaded!
        originalThread = nil
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchMode = true
        api.cancel()
        tableView.mj_header.isHidden = true
        originalThread = threads
        originalThreadLoaded = threadLoaded
        threads = [[SMThread]]()
        threadLoaded = 0
        searchController.searchBar.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(forText: searchString, scope: selectedIndex)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        threads = [[SMThread]]()
        threadLoaded = 0
        searchController?.searchBar.becomeFirstResponder()
    }
    
    func search(forText searchString: String?, scope: Int) {
        if let boardID = self.boardID, let searchString = searchString, !searchString.isEmpty {
            self.threadLoaded = 0
            let currentMode = searchMode
            networkActivityIndicatorStart(withHUD: true)
            var result: [SMThread]?
            DispatchQueue.global().async {
                if scope == 0 {
                    result = self.api.searchArticleInBoard(boardID: boardID,
                                                           title: searchString,
                                                           user: nil,
                                                           inRange: self.threadRange)
                } else if scope == 1 {
                    result = self.api.searchArticleInBoard(boardID: boardID,
                                                           title: nil,
                                                           user: searchString,
                                                           inRange: self.threadRange)
                }
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: true)
                    if currentMode != self.searchMode { return } //模式已经改变，则丢弃数据
                    self.threads.removeAll()
                    if let result = result {
                        self.threads.append(result)
                        self.threadLoaded += result.count
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ArticleListViewCell.self, forCellReuseIdentifier: kArticleListCellIdentifier)
        
        // search related
        definesPresentationContext = true
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchBar.scopeButtonTitles = ["标题关键字", "同作者"]
        if #available(iOS 9.1, *) {
            searchController?.obscuresBackgroundDuringPresentation = false
        } else {
            searchController?.dimsBackgroundDuringPresentation = false
        }
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        searchController?.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
        
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                           target: self,
                                           action: #selector(pressSearchButton(_:)))
        let composeButton = UIBarButtonItem(barButtonSystemItem: .add,
                                            target: self,
                                            action: #selector(composeArticle(_:)))
        navigationItem.rightBarButtonItems = [composeButton, searchButton]
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    deinit {
        searchController?.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
    }
    
    override func clearContent() {
        threads.removeAll()
    }
    
    @objc private func pressSearchButton(_ sender: UIBarButtonItem) {
        if tableView.tableHeaderView == nil {
            if let searchController = searchController {
                tableView.tableHeaderView = searchController.searchBar
                tableView.scrollRectToVisible(searchController.searchBar.frame, animated: false)
                searchController.isActive = true
            }
        }
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        threadLoaded = 0
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            networkActivityIndicatorStart(withHUD: showHUD)
            DispatchQueue.global().async {
                var threadSection = self.api.getThreadListForBoard(boardID: boardID,
                                                                   inRange: self.threadRange,
                                                                   brcmode: .NotClear)
                if self.setting.hideAlwaysOnTopThread {
                    threadSection = threadSection?.filter {
                        !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                    }
                }
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: showHUD)
                    completion?()
                    if currentMode != self.searchMode { return } //如果模式已经被切换，则数据丢弃
                    if let threadSection = threadSection {
                        self.threads.removeAll()
                        self.threadLoaded += threadSection.count
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
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
            
            let currentMode = self.searchMode
            let searchString = self.searchString
            let selectedIndex = self.selectedIndex
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                var threadSection: [SMThread]?
                if self.searchMode {
                    if selectedIndex == 0 {
                        threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                      title: searchString,
                                                                      user: nil,
                                                                      inRange: self.threadRange)
                    } else if selectedIndex == 1 {
                        threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                      title: nil,
                                                                      user: searchString,
                                                                      inRange: self.threadRange)
                    }
                } else {
                    threadSection = self.api.getThreadListForBoard(boardID: boardID,
                                                                   inRange: self.threadRange,
                                                                   brcmode: .NotClear)
                }
                // 过滤掉置顶帖
                if self.setting.hideAlwaysOnTopThread && !self.searchMode {
                    threadSection = threadSection?.filter {
                        !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                    }
                }
                // 过滤掉重复的帖子
                let loadedThreadIds = self.threads.reduce(Set<Int>()) {
                    $0.union(Set($1.map { $0.id }))
                }
                threadSection = threadSection?.filter {
                    !loadedThreadIds.contains($0.id)
                }
                DispatchQueue.main.async {
                    self._isFetchingMoreData = false
                    networkActivityIndicatorStop()
                    if self.searchMode != currentMode {
                        return //如果模式已经改变，则此数据需要丢弃
                    }
                    if let threadSection = threadSection, threadSection.count > 0 {
                        self.threadLoaded += threadSection.count
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
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
        acvc.boardID = thread.boardID
        acvc.boardName = thread.boardName
        acvc.title = thread.subject
        acvc.hidesBottomBarWhenPushed = true
        if thread.flags.hasPrefix("*") {
            var readThread = thread
            let flags = thread.flags
            readThread.flags = " " + flags[flags.index(after: flags.startIndex)...]
            threads[indexPath.section][indexPath.row] = readThread
        }
        
        show(acvc, sender: self)
    }
    
    @objc private func composeArticle(_ sender: UIBarButtonItem) {
        let cavc = ComposeArticleController()
        cavc.boardID = boardID
        cavc.completionHandler = { [unowned self] in
            self.fetchDataDirectly(showHUD: false)
        }
        let nvc = NTNavigationController(rootViewController: cavc)
        nvc.modalPresentationStyle = .formSheet
        present(nvc, animated: true)
    }
}

extension ArticleListViewController: UIViewControllerPreviewingDelegate, SmthViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard
            let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let acvc = ArticleContentViewController()
        let thread = threads[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.boardName = thread.boardName
        acvc.title = thread.subject
        acvc.previewDelegate = self
        acvc.hidesBottomBarWhenPushed = true
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return acvc
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let rect = previewingContext.sourceRect
        let center = CGPoint(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
        guard let indexPath = tableView.indexPathForRow(at: center) else { return }
        let thread = threads[indexPath.section][indexPath.row]
        
        if thread.flags.hasPrefix("*") {
            var readThread = thread
            let flags = thread.flags
            readThread.flags = " " + flags[flags.index(after: flags.startIndex)...]
            threads[indexPath.section][indexPath.row] = readThread
        }
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }
    
    func previewActionItems(for viewController: UIViewController) -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()
        if let acvc = viewController as? ArticleContentViewController {
            if let boardID = acvc.boardID, let articleID = acvc.articleID {
                let urlString: String
                switch self.setting.displayMode {
                case .nForum:
                    urlString = "https://www.newsmth.net/nForum/#!article/\(boardID)/\(articleID)"
                case .www2:
                    urlString = "https://www.newsmth.net/bbstcon.php?board=\(boardID)&gid=\(articleID)"
                case .mobile:
                    urlString = "https://m.newsmth.net/article/\(boardID)/\(articleID)"
                }
                let openAction = UIPreviewAction(title: "浏览网页版", style: .default) {[unowned self] (action, controller) in
                    let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                    self.present(webViewController, animated: true)
                }
                actions.append(openAction)
                if let cell = cell(for: articleID, and: boardID) {
                    let shareAction = UIPreviewAction(title: "分享本帖", style: .default) { [unowned self] (action, controller) in
                        let title = "水木\(acvc.boardName ?? boardID)版：【\(acvc.title ?? "无标题")】"
                        let url = URL(string: urlString)!
                        let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                              applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = cell
                        activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                        self.present(activityViewController, animated: true)
                    }
                    actions.append(shareAction)
                }
            }
        }
        return actions
    }
    
    private func cell(for articleID: Int, and boardID: String) -> UITableViewCell? {
        for section in 0..<threads.count {
            for row in 0..<threads[section].count {
                let thread = threads[section][row]
                if thread.id == articleID && thread.boardID == boardID {
                    return tableView.cellForRow(at: IndexPath(row: row, section: section))
                }
            }
        }
        return nil
    }
}
