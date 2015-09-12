//
//  FavListViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/17.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class FavListViewController: BaseTableViewController {

    var boardID: Int = 0
    private var favorites = [SMBoard]()

    override func clearContent() {
        super.clearContent()
        favorites.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if navigationItem.rightBarButtonItem != nil { //不能在子目录下进行收藏删除
            navigationItem.leftBarButtonItem = editButtonItem()
        }
    }


    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let favBoards = self.api.getFavBoardList(self.boardID)
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                self.tableView.header.endRefreshing()
                if let favBoards = favBoards {
                    self.favorites.removeAll()
                    self.favorites += favBoards
                }
                self.tableView?.reloadData()
                self.api.displayErrorIfNeeded()
            }
        }
    }


    @IBAction func addFavorite(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "请输入要收藏的版面ID", message: nil, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "确定", style: .Default) { [unowned alert] action in
            if let textField = alert.textFields?.first {
                let board = textField.text!
                self.addFavoriteWithBoardID(board)
            }
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        alert.addTextFieldWithConfigurationHandler { textField in
            textField.keyboardType = .ASCIICapable
            textField.autocorrectionType = .No
            textField.returnKeyType = .Done
        }
        presentViewController(alert, animated: true, completion: nil)
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
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
                        self.fetchData()
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

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

    private struct Static {
        static let boardIdentifier = "Board"
        static let directoryIdentifier = "Directory"
        static let flvcIdentifier = "FavListViewController"
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let fav = favorites[indexPath.row]
        var cell: UITableViewCell
        if (fav.flag != -1) && (fav.flag & 0x400 == 0) { //是版面
            cell = tableView.dequeueReusableCellWithIdentifier(Static.boardIdentifier, forIndexPath: indexPath) 
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(Static.directoryIdentifier, forIndexPath: indexPath) 
        }
        // Configure the cell...
        cell.textLabel?.text = fav.name
        cell.detailTextLabel?.text = fav.boardID
        cell.textLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        cell.detailTextLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let board = favorites[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            if let flvc = storyboard?.instantiateViewControllerWithIdentifier(Static.flvcIdentifier) as? FavListViewController {
                flvc.title = board.name
                flvc.boardID = board.bid
                flvc.navigationItem.rightBarButtonItem = nil // 不能在子目录下添加收藏
                showViewController(flvc, sender: self)
            }
        }

    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if navigationItem.rightBarButtonItem == nil {
            return false //不能在子目录下进行收藏删除
        }
        let boardFlag = favorites[indexPath.row].flag
        if (boardFlag != -1) && (boardFlag & 0x400 == 0) { //版面
            return true
        } else { //目录
            return false
        }
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let boardID = favorites[indexPath.row].boardID
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.api.deleteFavorite(boardID)
                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    if self.api.errorCode == 0 {
                        self.favorites.removeAtIndex(indexPath.row)
                        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    } else {
                        let hud = MBProgressHUD.showHUDAddedTo(self.navigationController?.view, animated: true)
                        hud.mode = .Text
                        hud.labelText = self.api.errorDescription
                        hud.hide(true, afterDelay: 1)
                    }
                }
            }
        }
    }


    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let
            alvc = segue.destinationViewController as? ArticleListViewController,
            cell = sender as? UITableViewCell,
            indexPath = tableView.indexPathForCell(cell)
        {

            let board = favorites[indexPath.row]
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.hidesBottomBarWhenPushed = true
        }
    }

}
