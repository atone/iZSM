//
//  ArticleContentTableViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/7.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit



class ArticleContentViewController: UITableViewController, ComposeArticleControllerDelegate {
    private struct Static {
        static let ArticleContentCellIdentifier = "ArticleContentCell"
    }

    private var smarticles = [[SMArticle]]()

    private let api = SmthAPI()
    private let setting = AppSetting.sharedSetting()

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
        tableView.registerClass(ArticleContentCell.self, forCellReuseIdentifier: Static.ArticleContentCellIdentifier)
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView

        tableView.addLegendHeaderWithRefreshingTarget(self, refreshingAction: #selector(ArticleContentViewController.fetchDataDirectly))
        tableView.header.updatedTimeHidden = true
        tableView.addLegendFooterWithRefreshingTarget(self, refreshingAction: #selector(ArticleContentViewController.fetchMoreData))
        tableView.footer.setTitle("", forState: MJRefreshFooterStateIdle)
        fetchData()
    }

    @IBAction func reverse(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        switch setting.sortMode {
        case .LaterPostFirst:
            let action = UIAlertAction(title: "最早回复在前", style: .Default) { [unowned self] action in
                self.setting.sortMode = .Normal
                self.fetchData()
            }
            actionSheet.addAction(action)
        case .Normal:
            let action = UIAlertAction(title: "最新回复在前", style: .Default) { [unowned self] action in
                self.setting.sortMode = .LaterPostFirst
                self.fetchData()
            }
            actionSheet.addAction(action)
        }
        if fromTopTen {
            if let boardID = self.boardID, boardName = self.boardName {
                let gotoBoardAction = UIAlertAction(title: "进入 \(boardName) 版", style: .Default) {[unowned self] action in
                    if let alvc = self.storyboard?.instantiateViewControllerWithIdentifier("ArticleListViewController") as? ArticleListViewController {
                        alvc.boardID = boardID
                        alvc.boardName = boardName
                        alvc.hidesBottomBarWhenPushed = true
                        self.showViewController(alvc, sender: self)
                    }
                }
                actionSheet.addAction(gotoBoardAction)
            }
        }
        actionSheet.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        actionSheet.popoverPresentationController?.barButtonItem = sender
        presentViewController(actionSheet, animated: true, completion: nil)
    }


    func fetchDataDirectly() {
        self.smarticles.removeAll()
        self.currentArticleNumber = 0
        if let boardID = self.boardID, articleID = self.articleID {
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let smArticles = self.api.getThreadContentInBoard(boardID, articleID: articleID, threadRange: self.threadRange, replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()

                if self.fromTopTen && self.boardName == nil { // get boardName
                    if let boards = self.api.queryBoard(boardID) {
                        for board in boards {
                            if board.boardID == boardID {
                                self.boardName = board.name
                                break
                            }
                        }
                    }
                }

                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    self.tableView.header.endRefreshing()
                    self.tableView.footer.hidden = false
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
            self.tableView.header.endRefreshing()
            tableView.footer.hidden = false
        }
    }

    func fetchData() {
        tableView.header.beginRefreshing()
        tableView.footer.hidden = true
    }

    // ComposeArticleControllerDelegate
    func articleDidPosted() {
        fetchMoreData()
    }

    func fetchMoreData() {
        if let boardID = self.boardID, articleID = self.articleID {
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let smArticles = self.api.getThreadContentInBoard(boardID, articleID: articleID, threadRange: self.threadRange, replyMode: self.setting.sortMode)
                let totalArticleNumber = self.api.getLastThreadCount()

                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    if let smArticles = smArticles {
                        let newIndexSet = NSIndexSet(index: self.smarticles.count)
                        self.smarticles.append(smArticles)
                        self.currentArticleNumber += smArticles.count
                        self.totalArticleNumber = totalArticleNumber
                        self.tableView.insertSections(newIndexSet, withRowAnimation: .None)
                    }
                    self.api.displayErrorIfNeeded()
                    self.tableView.footer.endRefreshing()
                    if self.totalArticleNumber == self.currentArticleNumber {
                        self.tableView.footer.setTitle("没有新帖子了", forState: MJRefreshFooterStateIdle)
                    } else {
                        self.tableView.footer.setTitle("", forState: MJRefreshFooterStateIdle)
                    }
                }
            }
        } else {
            tableView.footer.endRefreshing()
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return smarticles.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smarticles[section].count
    }

    private func articleCellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.ArticleContentCellIdentifier, forIndexPath: indexPath) as! ArticleContentCell
        configureArticleCell(cell, atIndexPath: indexPath)
        return cell
    }

    private func configureArticleCell(cell: ArticleContentCell, atIndexPath indexPath: NSIndexPath) {
        let smarticle = smarticles[indexPath.section][indexPath.row]
        var floor = smarticle.floor
        if setting.sortMode == .LaterPostFirst && floor != 0 {
            floor = totalArticleNumber - floor
        }
        cell.setData(displayFloor: floor, smarticle: smarticle, controller: self, delegate: self)
        cell.preservesSuperviewLayoutMargins = false
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return articleCellAtIndexPath(indexPath)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return tableView.fd_heightForCellWithIdentifier(Static.ArticleContentCellIdentifier) { (cell) -> Void in
            if let configureCell = cell as? ArticleContentCell {
                configureCell.fd_enforceFrameLayout = true
                self.configureArticleCell(configureCell, atIndexPath: indexPath)
            }
        }
    }
}

