//
//  BoardListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class BoardListViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate {
    
    private let kBoardIdentifier = "Board"
    private let kDirectoryIdentifier = "Directory"
    
    var boardID = 0
    var sectionID = 0
    var flag: Int = 0
    private var boards: [SMBoard] = [SMBoard]() {
        didSet { tableView?.reloadData() }
    }
    
    var originalBoards: [SMBoard]?
    var searchMode = false
    var searchString: String {
        return searchController?.searchBar.text ?? ""
    }
    
    private var searchController: UISearchController?
    
    func didDismissSearchController(_ searchController: UISearchController) {
        tableView.tableHeaderView = nil
        searchMode = false
        tableView.mj_header.isHidden = false
        boards = originalBoards ?? [SMBoard]()
        originalBoards = nil
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        searchMode = true
        tableView.mj_header.endRefreshing()
        SVProgressHUD.dismiss()
        tableView.mj_header.isHidden = true
        originalBoards = boards
        boards = [SMBoard]()
        searchController.searchBar.becomeFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchString.isEmpty { return }
        let currentMode = searchMode
        SVProgressHUD.show()
        networkActivityIndicatorStart()
        var result: [SMBoard]?
        
        DispatchQueue.global().async {
            result = self.api.queryBoard(query: self.searchString)
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
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
            if let searchController = searchController {
                tableView.tableHeaderView = searchController.searchBar
                tableView.scrollRectToVisible(searchController.searchBar.frame, animated: false)
                searchController.isActive = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // search related
        definesPresentationContext = true
        searchController = UISearchController(searchResultsController: nil)
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        //searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
        if boardID == 0 { //只在根目录下显示搜索
            let searchButton = UIBarButtonItem(barButtonSystemItem: .search,
                                               target: self,
                                               action: #selector(pressSearchButton(sender:)))
            navigationItem.rightBarButtonItem = searchButton
        }
        
        // add long press gesture recognizer
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self,
                                                                    action: #selector(handleLongPress(gestureRecognizer:))))
    }
    
    deinit {
        searchController?.loadViewIfNeeded()  // workaround for bug: [Warning] Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior <UISearchController: 0x10cd30220>
    }
    
    override func clearContent() {
        super.clearContent()
        boards.removeAll()
    }
    
    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            var boardList = [SMBoard]()
            if self.flag > 0  && (self.flag & 0x400 != 0) { //是目录
                if let boards = self.api.getBoardListInSection(section: self.sectionID, group: self.boardID) {
                    boardList = boards
                }
                
            } else { //是版面
                if let boards = self.api.getBoardList(group: self.boardID) {
                    boardList = boards
                }
            }
            
            boardList.sort { (b1, b2) -> Bool in
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
            
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                self.tableView.mj_header.endRefreshing()
                SVProgressHUD.dismiss()
                self.boards.removeAll()
                self.boards += boardList
                self.api.displayErrorIfNeeded()
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let board = boards[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let blvc =  BoardListViewController()
            if let r = board.name.range(of: " ") {
                blvc.title = board.name.substring(to: r.lowerBound)
            } else {
                blvc.title = board.name
            }
            blvc.boardID = board.bid
            blvc.sectionID = board.section
            blvc.flag = board.flag
            show(blvc, sender: self)
        } else {
            let alvc = ArticleListViewController()
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.hidesBottomBarWhenPushed = true
            show(alvc, sender: self)
        }
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boards.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let board = boards[indexPath.row]
        var cell: UITableViewCell
        if (board.flag != -1) && (board.flag & 0x400 == 0) { //是版面
            if let newCell = tableView.dequeueReusableCell(withIdentifier: kBoardIdentifier) {
                cell = newCell
            } else {
                cell = UITableViewCell(style: .value1, reuseIdentifier: kBoardIdentifier)
            }
            cell.textLabel?.text = board.name
            cell.detailTextLabel?.text = board.boardID
        } else {
            if let newCell = tableView.dequeueReusableCell(withIdentifier: kDirectoryIdentifier) {
                cell = newCell
            } else {
                cell = UITableViewCell(style: .value1, reuseIdentifier: kDirectoryIdentifier)
            }
            let name = board.name
            let splits = name.components(separatedBy: CharacterSet.whitespaces).filter { $0.characters.count > 0 }
            cell.textLabel?.text = splits.first
            if splits.count <= 1 {
                cell.detailTextLabel?.text = nil
            } else {
                cell.detailTextLabel?.text = splits[1..<splits.count].joined(separator: " ")
            }
        }
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        return cell
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: point) {
                let board = boards[indexPath.row]
                if (board.flag != -1) && (board.flag & 0x400 == 0) { //是版面
                    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    let addFavAction = UIAlertAction(title: "添加到收藏夹", style: .default) { action in
                        self.addFavoriteWithBoardID(boardID: board.boardID)
                    }
                    actionSheet.addAction(addFavAction)
                    actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    let cell = tableView.cellForRow(at: indexPath)!
                    actionSheet.popoverPresentationController?.sourceView = cell
                    actionSheet.popoverPresentationController?.sourceRect = cell.bounds
                    present(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    func addFavoriteWithBoardID(boardID: String) {
        networkActivityIndicatorStart()
        SVProgressHUD.show()
        DispatchQueue.global().async {
            self.api.addFavorite(boardID: boardID)
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                SVProgressHUD.dismiss()
                if self.api.errorCode == 0 {
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil)
                } else if self.api.errorCode == 10319 {
                    SVProgressHUD.showInfo(withStatus: "该版面已在收藏夹中")
                } else if self.api.errorDescription != nil && self.api.errorDescription != "" {
                    SVProgressHUD.showError(withStatus: self.api.errorDescription)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
            }
        }
    }
    
}
