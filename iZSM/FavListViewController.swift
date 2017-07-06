//
//  FavListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class FavListViewController: BaseTableViewController {
    static let kUpdateFavListNotification = Notification.Name("UpdateFavListNotification")
    private let kBoardIdentifier = "Board"
    private let kDirectoryIdentifier = "Directory"
    
    var boardID: Int = 0
    private var favorites = [SMBoard]()
    
    override func clearContent() {
        super.clearContent()
        favorites.removeAll()
    }
    
    func setUpdateFavList(notification: Notification) {
        clearContent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if boardID == 0 { //不能在子目录下进行收藏删除和添加
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                target: self,
                                                                action: #selector(addFavorite(sender:)))
            navigationItem.leftBarButtonItem = editButtonItem
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setUpdateFavList(notification:)),
                                               name: FavListViewController.kUpdateFavListNotification,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            let favBoards = self.api.getFavBoardList(group: self.boardID)
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                self.tableView.mj_header.endRefreshing()
                if let favBoards = favBoards {
                    self.favorites.removeAll()
                    self.favorites += favBoards
                }
                self.tableView?.reloadData()
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    
    func addFavorite(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "请输入要收藏的版面ID", message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert] action in
            if let textField = alert.textFields?.first {
                let board = textField.text!
                self.addFavoriteWithBoardID(boardID: board)
            }
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.keyboardType = .asciiCapable
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
        }
        present(alert, animated: true, completion: nil)
    }
    
    func addFavoriteWithBoardID(boardID: String) {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            self.api.addFavorite(boardID: boardID)
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if self.api.errorCode == 0 {
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.fetchData()
                    }
                } else if self.api.errorCode == 10319 {
                    SVProgressHUD.showInfo(withStatus: "该版面已在收藏夹中")
                } else if self.api.errorDescription != nil && self.api.errorDescription != "" {
                    SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let fav = favorites[indexPath.row]
        var cell: UITableViewCell
        if (fav.flag != -1) && (fav.flag & 0x400 == 0) { //是版面
            if let newCell = tableView.dequeueReusableCell(withIdentifier: kBoardIdentifier) {
                cell = newCell
            } else {
                cell = UITableViewCell(style: .value1, reuseIdentifier: kBoardIdentifier)
            }
        } else { // 是目录
            if let newCell = tableView.dequeueReusableCell(withIdentifier: kDirectoryIdentifier) {
                cell = newCell
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: kDirectoryIdentifier)
            }
        }
        // Configure the cell...
        cell.textLabel?.text = fav.name
        cell.detailTextLabel?.text = fav.boardID
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let board = favorites[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let flvc = FavListViewController()
            flvc.title = board.name
            flvc.boardID = board.bid
            show(flvc, sender: self)
        } else {
            let alvc = ArticleListViewController()
            let board = favorites[indexPath.row]
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.hidesBottomBarWhenPushed = true
            show(alvc, sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if boardID != 0 {
            return false //不能在子目录下进行收藏删除
        }
        let boardFlag = favorites[indexPath.row].flag
        if (boardFlag != -1) && (boardFlag & 0x400 == 0) { //版面
            return true
        } else { //目录
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let boardID = favorites[indexPath.row].boardID
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                self.api.deleteFavorite(boardID: boardID)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if self.api.errorCode == 0 {
                        self.favorites.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    } else {
                        SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                    }
                }
            }
        }
    }
}