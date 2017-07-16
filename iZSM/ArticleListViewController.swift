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
    
    var threadLoaded = 0
    private var threadRange: NSRange {
        return NSMakeRange(threadLoaded, setting.threadCountPerSection)
    }
    var threads: [[SMThread]] = [[SMThread]]() {
        didSet { tableView?.reloadData() }
    }
    
    var originalThreadLoaded: Int? = nil
    var originalThread: [[SMThread]]?
    var searchMode = false
    
    var searchString: String? {
        return searchController.searchBar.text
    }
    var selectedIndex: Int {
        return searchController.searchBar.selectedScopeButtonIndex
    }
    
    private lazy var searchController: UISearchController = {
        let tmpController = UISearchController(searchResultsController: nil)
        tmpController.searchBar.scopeButtonTitles = ["标题", "用户"]
        tmpController.dimsBackgroundDuringPresentation = false
        tmpController.delegate = self
        tmpController.searchBar.delegate = self
        tmpController.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
        return tmpController
    }()
    
    func didDismissSearchController(_ searchController: UISearchController) {
        tableView.tableHeaderView = nil
        searchMode = false
        tableView.mj_header.isHidden = false
        threads = originalThread!
        threadLoaded = originalThreadLoaded!
        originalThread = nil
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchMode = true
        tableView.mj_header.endRefreshing()
        SVProgressHUD.dismiss()
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
        search(forText: searchString, scope: selectedScope)
    }
    
    func search(forText searchString: String?, scope: Int) {
        if let boardID = self.boardID, let searchString = searchString {
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
        
        let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                           target: self,
                                           action: #selector(pressSearchButton(sender:)))
        let composeButton = UIBarButtonItem(barButtonSystemItem: .add,
                                            target: self,
                                            action: #selector(composeArticle(sender:)))
        navigationItem.rightBarButtonItems = [composeButton, searchButton]
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    deinit {
        searchController.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
    }
    
    override func clearContent() {
        threads.removeAll()
    }
    
    func pressSearchButton(sender: UIBarButtonItem) {
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = searchController.searchBar
            tableView.scrollRectToVisible(searchController.searchBar.frame, animated: false)
            searchController.isActive = true
        }
    }
    

    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        threadLoaded = 0
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            networkActivityIndicatorStart(withHUD: showHUD)
            DispatchQueue.global().async {
                let threadSection = self.api.getThreadListForBoard(boardID: boardID,
                                                                   inRange: self.threadRange,
                                                                   brcmode: .NotClear)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: showHUD)
                    completion?()
                    if currentMode != self.searchMode { return } //如果模式已经被切换，则数据丢弃
                    if var threadSection = threadSection {
                        self.threads.removeAll()
                        self.threadLoaded += threadSection.count
                        if self.setting.hideAlwaysOnTopThread {
                            threadSection = threadSection.filter {
                                !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                            }
                        }
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            completion?()
        }
    }
    
    override func fetchMoreData() {
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                var threadSection: [SMThread]?
                if self.searchMode {
                    if self.selectedIndex == 0 {
                        threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                      title: self.searchString,
                                                                      user: nil,
                                                                      inRange: self.threadRange)
                    } else if self.selectedIndex == 1 {
                        threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                      title: nil,
                                                                      user: self.searchString,
                                                                      inRange: self.threadRange)
                    }
                } else {
                    threadSection = self.api.getThreadListForBoard(boardID: boardID,
                                                                   inRange: self.threadRange,
                                                                   brcmode: .NotClear)
                }
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if self.searchMode != currentMode {
                        return //如果模式已经改变，则此数据需要丢弃
                    }
                    if var threadSection = threadSection {
                        self.threadLoaded += threadSection.count
                        if self.setting.hideAlwaysOnTopThread && !self.searchMode {
                            threadSection = threadSection.filter {
                                !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D")
                            }
                        }
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
            readThread.flags = " " + flags.substring(from: flags.index(after: flags.startIndex))
            threads[indexPath.section][indexPath.row] = readThread
        }
        
        show(acvc, sender: self)
    }
    
    func composeArticle(sender: UIBarButtonItem) {
        let cavc = ComposeArticleController()
        cavc.boardID = boardID
        cavc.delegate = self
        let nvc = NTNavigationController(rootViewController: cavc)
        nvc.modalPresentationStyle = .formSheet
        present(nvc, animated: true, completion: nil)
    }
}

extension ArticleListViewController: UIViewControllerPreviewingDelegate {
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
            readThread.flags = " " + flags.substring(from: flags.index(after: flags.startIndex))
            threads[indexPath.section][indexPath.row] = readThread
        }
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }
}

extension ArticleListViewController: ComposeArticleControllerDelegate {
    // ComposeArticleControllerDelegate
    func articleDidPosted() {
        fetchDataDirectly(showHUD: false)
    }
}
