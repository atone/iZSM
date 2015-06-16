//
//  ArticleListViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/17.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ArticleListViewController: BaseTableViewController, ComposeArticleControllerDelegate, UISearchControllerDelegate, UISearchBarDelegate {
    var boardID: String?
    var boardName: String? {
        didSet { title = boardName }
    }

    var threadLoaded = 0
    private var threadRange: NSRange {
        return NSMakeRange(threadLoaded, setting.threadCountPerSection)
    }
    private var threads: [[SMThread]] = [[SMThread]]() {
        didSet { tableView?.reloadData() }
    }


    var originalThreadLoaded: Int? = nil
    var originalThread: [[SMThread]]?
    var searchMode = false

    var searchString: String {
        return searchController.searchBar.text
    }
    var selectedIndex: Int {
        return searchController.searchBar.selectedScopeButtonIndex
    }

    private let searchController = UISearchController(searchResultsController: nil)

    func didDismissSearchController(searchController: UISearchController) {
        tableView.tableHeaderView = nil
        searchMode = false
        tableView.header.hidden = false
        threads = originalThread!
        threadLoaded = originalThreadLoaded!
        originalThread = nil
    }
    func didPresentSearchController(searchController: UISearchController) {
        searchMode = true
        tableView.header.endRefreshing()
        tableView.header.hidden = true
        originalThread = threads
        originalThreadLoaded = threadLoaded
        threads = [[SMThread]]()
        threadLoaded = 0
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchForText(searchString, scope: selectedIndex)
    }

    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchForText(searchString, scope: selectedScope)
    }

    func searchForText(searchString: String, scope: Int) {
        if searchString.isEmpty { return }
        if let boardID = self.boardID {
            self.threadLoaded = 0
            let currentMode = searchMode
            let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            networkActivityIndicatorStart()
            var result: [SMThread]?
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if scope == 0 {
                    result = self.api.searchArticleInBoard(boardID, title: searchString, user: nil, inRange: self.threadRange)
                } else if scope == 1 {
                    result = self.api.searchArticleInBoard(boardID, title: nil, user: searchString, inRange: self.threadRange)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    hud.hide(true)
                    networkActivityIndicatorStop()
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

        // search related
        definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = ["标题", "用户"]
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        let searchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "pressSearchButton:")
        navigationItem.rightBarButtonItems?.append(searchButton)
    }

    override func clearContent() {
        super.clearContent()
        threads.removeAll()
    }

    func pressSearchButton(sender: UIBarButtonItem) {
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = searchController.searchBar
            tableView.scrollRectToVisible(searchController.searchBar.frame, animated: false)
            searchController.active = true
        }
    }

    // ComposeArticleControllerDelegate
    func articleDidPosted() {
        fetchDataDirectly()
    }

    override func fetchDataDirectly() {
        threadLoaded = 0
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let threadSection = self.api.getThreadListForBoard(boardID, inRange: self.threadRange, brcmode: .NotClear)

                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    self.tableView.header.endRefreshing()
                    if currentMode != self.searchMode { return } //如果模式已经被切换，则数据丢弃
                    if var threadSection = threadSection {
                        self.threads.removeAll()
                        self.threadLoaded += threadSection.count
                        if self.setting.hideAlwaysOnTopThread {
                            threadSection = threadSection.filter { !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D") }
                        }
                        self.threads.append(threadSection)

                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            self.refreshControl?.endRefreshing()
        }
    }

    override func fetchMoreData() {
        if let boardID = self.boardID {
            let currentMode = self.searchMode
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var threadSection: [SMThread]?
                if self.searchMode {
                    if self.selectedIndex == 0 {
                        threadSection = self.api.searchArticleInBoard(boardID, title: self.searchString, user: nil, inRange: self.threadRange)
                    } else if self.selectedIndex == 1 {
                        threadSection = self.api.searchArticleInBoard(boardID, title: nil, user: self.searchString, inRange: self.threadRange)
                    }
                } else {
                    threadSection = self.api.getThreadListForBoard(boardID, inRange: self.threadRange, brcmode: .NotClear)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    if self.searchMode != currentMode {
                        return //如果模式已经改变，则此数据需要丢弃
                    }
                    if var threadSection = threadSection {
                        self.threadLoaded += threadSection.count
                        if self.setting.hideAlwaysOnTopThread && !self.searchMode {
                            threadSection = threadSection.filter { !$0.flags.hasPrefix("d") && !$0.flags.hasPrefix("D") }
                        }
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return threads.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads[section].count
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if threads.isEmpty {
            return
        }
        if indexPath.section == threads.count - 1 && indexPath.row == threads[indexPath.section].count / 3 * 2 {
            fetchMoreData()
        }
    }

    private struct Static {
        static let ArticleListCellIdentifier = "ArticleListCell"
        static let ArticleSegueIdentifier = "Article Content"
        static let ComposeSegueIdentifier = "Compose"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.ArticleListCellIdentifier, forIndexPath: indexPath) as! ArticleListCell
        cell.thread = threads[indexPath.section][indexPath.row]
        return cell
    }



    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Static.ArticleSegueIdentifier {
            var dvc = segue.destinationViewController as? UIViewController
            if let nvc = dvc as? UINavigationController {
                dvc = nvc.visibleViewController
            }

            if let
                acvc = dvc as? ArticleContentViewController,
                cell = sender as? UITableViewCell,
                indexPath = tableView.indexPathForCell(cell)
            {
                let thread = threads[indexPath.section][indexPath.row]
                acvc.articleID = thread.id
                acvc.boardID = thread.boardID
                acvc.boardName = thread.boardName
                acvc.title = thread.subject
                acvc.hidesBottomBarWhenPushed = true
                if thread.flags.hasPrefix("*") {
                    var readThread = thread
                    let flags = thread.flags
                    readThread.flags = " " + flags.substringFromIndex(flags.startIndex.successor())
                    threads[indexPath.section][indexPath.row] = readThread
                }
            }
        } else if segue.identifier == Static.ComposeSegueIdentifier {
            if let cavc = segue.destinationViewController as? ComposeArticleController {
                cavc.boardID = boardID
                cavc.delegate = self
            }
        }
    }
}
