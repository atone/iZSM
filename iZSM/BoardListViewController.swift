//
//  BoardListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class BoardListViewController: BaseTableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
    
    private let kBoardIdentifier = "Board"
    private let kDirectoryIdentifier = "Directory"
    
    private var indexMap = [String : IndexPath]()
    
    var boardID = 0
    var sectionID = 0
    var flag: Int = 0
    private var boards: [SMBoard] = [SMBoard]()
    
    var originalBoards: [SMBoard]?
    var searchMode = false
    var searchString = ""
    
    private var searchController: UISearchController?
    
    func didDismissSearchController(_ searchController: UISearchController) {
        searchMode = false
        api.cancel()
        refreshHeaderEnabled = true
        boards = originalBoards ?? [SMBoard]()
        originalBoards = nil
        tableView.reloadData()
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        searchMode = true
        api.cancel()
        refreshHeaderEnabled = false
        originalBoards = boards
        boards = [SMBoard]()
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let currentSearchString = searchController.searchBar.text else { return }
        if currentSearchString.isEmpty, let topSearchResult = SMBoardInfo.topSearchResult() {
            searchString = currentSearchString
            boards = topSearchResult
            tableView.reloadData()
            return
        }
        guard currentSearchString != searchString else { return }
        searchString = currentSearchString
        let currentMode = searchMode
        networkActivityIndicatorStart()
        var result: [SMBoard]?
        
        DispatchQueue.global().async {
            result = self.api.queryBoard(query: currentSearchString)
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if currentMode != self.searchMode || currentSearchString != self.searchString { return } //模式已经改变，则丢弃数据
                self.boards.removeAll()
                if let result = result {
                    self.boards += result
                    let filteredResult = result.filter { ($0.flag != -1) && ($0.flag & 0x400 == 0) }
                    SMBoardInfo.save(boardList: filteredResult)
                }
                self.tableView.reloadData()
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    override func viewDidLoad() {
        
        if boardID == 0 { //只在根目录下显示搜索
            // search related
            searchController = UISearchController(searchResultsController: nil)
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.delegate = self
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.placeholder = "版面名称/关键字搜索"
            navigationItem.searchController = searchController
            navigationItem.scrollEdgeAppearance = UINavigationBarAppearance() // fix transparent search bar
        }
        
        super.viewDidLoad()
    }
    
    override func clearContent() {
        boards.removeAll()
        tableView.reloadData()
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        networkActivityIndicatorStart(withHUD: showHUD)
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
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                self.boards.removeAll()
                self.boards += boardList
                self.tableView.reloadData()
                self.api.displayErrorIfNeeded()
                SMBoardInfo.save(boardList: boardList)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let board = boards[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let blvc =  BoardListViewController()
            if let r = board.name.range(of: " ") {
                blvc.title = String(board.name[..<r.lowerBound])
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
            alvc.boardManagers = board.manager.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            alvc.hidesBottomBarWhenPushed = true
            show(alvc, sender: self)
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchMode && searchString.isEmpty {
            return true
        }
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let board = boards.remove(at: indexPath.row)
            SMBoardInfo.clearHitCount(for: board.boardID)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
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
            let splits = name.components(separatedBy: .whitespaces).filter { $0.count > 0 }
            cell.textLabel?.text = splits.first
            if splits.count <= 1 {
                cell.detailTextLabel?.text = nil
            } else {
                cell.detailTextLabel?.text = splits[1..<splits.count].joined(separator: " ")
            }
        }
        let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        let subtitleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: subtitleDescr.pointSize * setting.fontScale)
        cell.textLabel?.textColor = UIColor(named: "MainText")
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && searchMode && searchString.isEmpty && !boards.isEmpty {
            return "常去版面"
        }
        return nil
    }
    
    func addFavoriteWithBoardID(boardID: String) {
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            self.api.addFavorite(boardID: boardID, group: 0)
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                if self.api.errorCode == 0 {
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil, userInfo: ["group_id": 0])
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
    
    func addMemberWithBoardID(boardID: String) {
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            let joinResult = self.api.joinMemberOfBoard(boardID: boardID)
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                if self.api.errorCode == 0 {
                    if joinResult == 0 {
                        SVProgressHUD.showSuccess(withStatus: "关注成功，您已是正式驻版用户")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "关注成功，尚需管理员审核成为正式驻版用户")
                    }
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil, userInfo: ["group_id": 0])
                } else if self.api.errorDescription != nil && self.api.errorDescription != "" {
                    SVProgressHUD.showError(withStatus: self.api.errorDescription)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
            }
        }
    }
}

extension BoardListViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let board = boards[indexPath.row]
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: board)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            if (board.flag != -1) && (board.flag & 0x400 == 0) {
                let addFavAction = UIAction(title: "收藏 \(board.name) 版", image: UIImage(systemName: "star")) { [unowned self] action in
                    self.addFavoriteWithBoardID(boardID: board.boardID)
                }
                let addMemAction = UIAction(title: "关注 \(board.name) 版 (驻版)", image: UIImage(systemName: "heart")) { [unowned self] action in
                    self.addMemberWithBoardID(boardID: board.boardID)
                }
                return UIMenu(title: "", children: [addFavAction, addMemAction])
            }
            return nil
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            let board = self.boards[indexPath.row]
            let vc = self.getViewController(with: board)
            self.show(vc, sender: self)
        }
    }
    
    private func getViewController(with board: SMBoard) -> BaseTableViewController {
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let blvc =  BoardListViewController()
            if let r = board.name.range(of: " ") {
                blvc.title = String(board.name[..<r.lowerBound])
            } else {
                blvc.title = board.name
            }
            blvc.boardID = board.bid
            blvc.sectionID = board.section
            blvc.flag = board.flag
            return blvc
        } else {
            let alvc = ArticleListViewController()
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.boardManagers = board.manager.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            alvc.hidesBottomBarWhenPushed = true
            return alvc
        }
    }
}
