//
//  BoardListSearchResultViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/8/13.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

class BoardListSearchResultViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    private let kBoardCellIdentifier = "BoardSearchResult"
    
    private var boards: [SMBoard] = []
    
    private var searchString = ""
    
    private var searchController = UISearchController(searchResultsController: nil)
    
    var completionHandler: ((BoardListSearchResultViewController, SMBoard) -> Void)?
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true)
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
        networkActivityIndicatorStart()
        api.searchBoard(query: currentSearchString) { (result) in
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if currentSearchString != self.searchString { return } //模式已经改变，则丢弃数据
                self.boards.removeAll()
                switch result {
                case .success(let boards):
                    let filtered = boards.filter { ($0.flag != -1) && ($0.flag & 0x400 == 0) }
                    self.boards += filtered
                    SMBoardInfo.save(boardList: filtered)
                case .failure(let error):
                    error.display()
                }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshHeaderEnabled = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "版面名称/关键字搜索"
        navigationItem.searchController = searchController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // don't call super.viewDidAppear(_:) to avoid fatal error
        searchController.isActive = true
    }
    
    override func clearContent() {
        boards.removeAll()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let board = boards[indexPath.row]
        if (board.flag != -1) && (board.flag & 0x400 == 0) && (completionHandler != nil) {
            SMBoardInfo.hit(for: board.boardID)
            completionHandler!(self, board)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if searchString.isEmpty {
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
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return boards.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let board = boards[indexPath.row]
        var cell: UITableViewCell
        if let newCell = tableView.dequeueReusableCell(withIdentifier: kBoardCellIdentifier) {
            cell = newCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: kBoardCellIdentifier)
        }
        cell.textLabel?.text = board.name
        cell.detailTextLabel?.text = board.boardID
        
        let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        if setting.useBoldFont {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        }
        let subtitleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: subtitleDescr.pointSize * setting.fontScale)
        cell.textLabel?.textColor = UIColor(named: "MainText")
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && searchString.isEmpty && !boards.isEmpty {
            return "常去版面"
        }
        return nil
    }
    
    static func searchResultController(title: String?, completionHandler: ((BoardListSearchResultViewController, SMBoard) -> Void)?) -> UIViewController {
        let searchResultController = BoardListSearchResultViewController()
        searchResultController.title = title
        searchResultController.completionHandler = completionHandler
        return NTNavigationController(rootViewController: searchResultController)
    }
}
