//
//  BoardListViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/16.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class BoardListViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate {


    var boardID = 0
    var sectionID = 0
    var flag: Int = 0
    private var boards: [SMBoard] = [SMBoard]() {
        didSet { tableView?.reloadData() }
    }

    var originalBoards: [SMBoard]?
    var searchMode = false
    var searchString: String {
        return searchController.searchBar.text!
    }

    private let searchController = UISearchController(searchResultsController: nil)

    func didDismissSearchController(searchController: UISearchController) {
        tableView.tableHeaderView = nil
        searchMode = false
        tableView.header.hidden = false
        boards = originalBoards!
        originalBoards = nil

    }

    func didPresentSearchController(searchController: UISearchController) {
        searchMode = true
        tableView.header.endRefreshing()
        tableView.header.hidden = true
        originalBoards = boards
        boards = [SMBoard]()
        searchController.searchBar.becomeFirstResponder()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchString.isEmpty { return }
        let currentMode = searchMode
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        networkActivityIndicatorStart()
        var result: [SMBoard]?
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            result = self.api.queryBoard(self.searchString)
            dispatch_async(dispatch_get_main_queue()) {
                hud.hide(true)
                networkActivityIndicatorStop()
                if currentMode != self.searchMode { return } //模式已经改变，则丢弃数据
                self.boards.removeAll()
                if let result = result {
                    self.boards += result
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }

    func pressSearchButton(sender: UIBarButtonItem) {
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = searchController.searchBar
            tableView.scrollRectToVisible(searchController.searchBar.frame, animated: false)
            searchController.active = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // search related
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        let searchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "pressSearchButton:")
        if boardID == 0 { //只在根目录下显示搜索
            navigationItem.rightBarButtonItem = searchButton
        }

        // add long press gesture recognizer
        let lpgr = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        tableView.addGestureRecognizer(lpgr)
    }

    override func clearContent() {
        super.clearContent()
        boards.removeAll()
    }

    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var boardList = [SMBoard]()
            if self.flag > 0  && (self.flag & 0x400 != 0) { //是目录
                if let boards = self.api.getBoardListInSection(self.sectionID, group: self.boardID) {
                    boardList = boards
                }

            } else { //是版面
                if let boards = self.api.getBoardList(self.boardID) {
                    boardList = boards
                }
            }

            boardList.sortInPlace{ (b1, b2) -> Bool in
                var flag_a = b1.flag
                var flag_b = b2.flag
                if flag_a == -1 || (flag_a & 0x400 != 0) {
                    flag_a = 1
                } else {
                    flag_a = 0
                }

                if flag_b == -1 || (flag_b & 0x400 != 0) {
                    flag_b = 1
                } else {
                    flag_b = 0
                }

                if flag_a == 0 && flag_b == 0 {
                    return b1.currentUsers >= b2.currentUsers
                } else {
                    return flag_a >= flag_b
                }
            }

            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                self.tableView.header.endRefreshing()
                self.boards.removeAll()
                self.boards += boardList
                self.api.displayErrorIfNeeded()
            }
            
        }
    }


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let board = boards[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            if let blvc = storyboard?.instantiateViewControllerWithIdentifier(Static.blvcIdentifier) as? BoardListViewController {
                if let r = board.name.rangeOfString(" ") {
                    blvc.title = board.name.substringToIndex(r.startIndex)
                } else {
                    blvc.title = board.name
                }
                blvc.boardID = board.bid
                blvc.sectionID = board.section
                blvc.flag = board.flag
                showViewController(blvc, sender: self)
            }
        }

    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boards.count
    }


    private struct Static {
        static let boardIdentifier = "Board"
        static let directoryIdentifier = "Directory"
        static let blvcIdentifier = "BoardListViewController"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let board = boards[indexPath.row]
        var cell: UITableViewCell
        if (board.flag != -1) && (board.flag & 0x400 == 0) { //是版面
            cell = tableView.dequeueReusableCellWithIdentifier(Static.boardIdentifier, forIndexPath: indexPath) 
            cell.textLabel?.text = board.name
            cell.detailTextLabel?.text = board.boardID
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(Static.directoryIdentifier, forIndexPath: indexPath) 
            let name = board.name
            if let r = name.rangeOfString(" ") {
                cell.textLabel?.text = name.substringToIndex(r.startIndex)
                cell.detailTextLabel?.text = name.substringFromIndex(r.endIndex)
            } else {
                cell.textLabel?.text = name
                cell.detailTextLabel?.text = nil
            }
        }
        cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        cell.detailTextLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        return cell
    }


    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .Began {
        let point = gestureRecognizer.locationInView(tableView)
            if let indexPath = tableView.indexPathForRowAtPoint(point) {
                let board = boards[indexPath.row]
                if (board.flag != -1) && (board.flag & 0x400 == 0) { //是版面
                    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                    let addFavAction = UIAlertAction(title: "添加到收藏夹", style: .Default) { action in
                        self.addFavoriteWithBoardID(board.boardID)
                    }
                    actionSheet.addAction(addFavAction)
                    actionSheet.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
                    let cell = tableView.cellForRowAtIndexPath(indexPath)!
                    actionSheet.popoverPresentationController?.sourceView = cell
                    actionSheet.popoverPresentationController?.sourceRect = cell.bounds
                    presentViewController(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }

    func addFavoriteWithBoardID(boardID: String) {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.api.addFavorite(boardID)
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
                hud.mode = .Text
                if self.api.errorCode == 0 {
                    hud.labelText = "添加成功"
                    if let nvc = (self.tabBarController?.viewControllers as? [UINavigationController])?[2],
                        flvc = nvc.visibleViewController as? FavListViewController
                    {
                        flvc.clearContent()
                    }
                } else if self.api.errorCode == 10319 {
                    hud.labelText = "该版面已在收藏夹中"
                } else if self.api.errorDescription != nil && self.api.errorDescription != "" {
                    hud.labelText = self.api.errorDescription
                } else {
                    hud.labelText = "出错了"
                }
                hud.hide(true, afterDelay: 1)
            }
        }
    }




    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let
            alvc = segue.destinationViewController as? ArticleListViewController,
            cell = sender as? UITableViewCell,
            indexPath = tableView.indexPathForCell(cell)
        {
            let board = boards[indexPath.row]
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.hidesBottomBarWhenPushed = true
        }
    }


}
