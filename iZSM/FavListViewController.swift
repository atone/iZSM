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
    
    private lazy var switcher: UISegmentedControl = {
        let switcher = UISegmentedControl(items: ["收藏夹", "驻版"])
        switcher.selectedSegmentIndex = 0
        switcher.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        switcher.addTarget(self, action: #selector(indexChanged(sender:)), for: .valueChanged)
        return switcher
    }()
    
    var index: Int = 0 {
        didSet {
            if switcher.selectedSegmentIndex != index {
                switcher.selectedSegmentIndex = index
            }
        }
    }
    
    var boardID: Int = 0
    fileprivate var favorites = [SMBoard]()
    
    override func clearContent() {
        favorites.removeAll()
        tableView?.reloadData()
    }
    
    func setUpdateFavList(notification: Notification) {
        fetchData(showHUD: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if boardID == 0 { //不能在子目录下进行收藏删除和添加，驻版没有子版面
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                target: self,
                                                                action: #selector(addFavorite(sender:)))
            navigationItem.leftBarButtonItem = editButtonItem
            navigationItem.titleView = switcher
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setUpdateFavList(notification:)),
                                               name: FavListViewController.kUpdateFavListNotification,
                                               object: nil)
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        guard let userID =  AppSetting.shared.username else {
            completion?()
            return
        }
        networkActivityIndicatorStart(withHUD: showHUD)
        DispatchQueue.global().async {
            var favBoards = [SMBoard]()
            if self.index == 0 {
                let ret = self.api.getFavBoardList(group: self.boardID) ?? [SMBoard]()
                favBoards += ret
            } else {
                let ret = self.api.getUserMemberList(userID: userID) ?? [SMMember]()
                favBoards += ret.map { $0.board }
            }
            
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                self.favorites.removeAll()
                self.favorites += favBoards
                self.tableView?.reloadData()
                self.api.displayErrorIfNeeded()
                SMBoardInfoUtil.save(boardList: favBoards)
            }
        }
    }
    
    func indexChanged(sender: UISegmentedControl) {
        index = sender.selectedSegmentIndex
        fetchDataDirectly(showHUD: true)
    }
    
    
    func addFavorite(sender: UIBarButtonItem) {
        let favMessage = "提示：记不住版面ID？没关系，在版面列表 (支持搜索) 下面长按待\(self.index == 0 ? "收藏" : "关注")的版面，也可以\(self.index == 0 ? "将版面添加到收藏夹" : "关注版面 (驻版)")。"
        let alert = UIAlertController(title: "请输入要\(self.index == 0 ? "收藏" : "关注")的版面ID", message: favMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alert] _ in
            if let textField = alert.textFields?.first {
                let board = textField.text!
                self.addFavoriteWithBoardID(boardID: board)
            }
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addTextField { textField in
            textField.keyboardType = .asciiCapable
            textField.autocorrectionType = .no
            textField.returnKeyType = .done
            textField.keyboardAppearance = self.setting.nightMode ? UIKeyboardAppearance.dark : UIKeyboardAppearance.default
        }
        present(alert, animated: true)
    }
    
    func addFavoriteWithBoardID(boardID: String) {
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            var joinResult = 0
            if self.index == 0 {
                self.api.addFavorite(boardID: boardID)
            } else {
                joinResult = self.api.joinMemberOfBoard(boardID: boardID)
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                if self.api.errorCode == 0 {
                    if self.index == 0 {
                        SVProgressHUD.showSuccess(withStatus: "添加成功")
                    } else if joinResult == 0 {
                        SVProgressHUD.showSuccess(withStatus: "关注成功，您已是正式驻版用户")
                    } else {
                        SVProgressHUD.showSuccess(withStatus: "关注成功，尚需管理员审核成为正式驻版用户")
                    }
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil)
                } else if self.api.errorCode == 10319 && self.index == 0 {
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
        cell.textLabel?.textColor = AppTheme.shared.textColor
        cell.detailTextLabel?.textColor = AppTheme.shared.lightTextColor
        cell.backgroundColor = AppTheme.shared.backgroundColor
        let selectedBackgroundView = UIView(frame: cell.contentView.bounds)
        selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell.selectedBackgroundView = selectedBackgroundView
        cell.selectedBackgroundView?.backgroundColor = AppTheme.shared.selectedBackgroundColor
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
                if self.index == 0 {
                    self.api.deleteFavorite(boardID: boardID)
                } else {
                    let _ = self.api.quitMemberOfBoard(boardID: boardID)
                }
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if self.api.errorCode == 0 {
                        self.favorites.remove(at: indexPath.row)
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                    } else {
                        SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                    }
                }
            }
        }
    }
}

extension FavListViewController : UIViewControllerPreviewingDelegate, SmthViewControllerPreviewingDelegate {
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard
            let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        previewingContext.sourceRect = cell.frame
        let board = favorites[indexPath.row]
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let flvc = FavListViewController()
            flvc.title = board.name
            flvc.boardID = board.bid
            return flvc
        } else {
            let alvc = ArticleListViewController()
            alvc.boardID = board.boardID
            alvc.boardName = board.name
            alvc.previewDelegate = self
            alvc.hidesBottomBarWhenPushed = true
            return alvc
        }
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }
    
    func previewActionItems(for viewController: UIViewController) -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()
        if let alvc = viewController as? ArticleListViewController, let boardID = alvc.boardID, let boardName = alvc.boardName {
            let title = "取消\(self.index == 0 ? "收藏" : "关注") \(boardName) 版"
            let delFavAction = UIPreviewAction(title: title, style: .destructive) { [unowned self] (action, controller) in
                networkActivityIndicatorStart()
                DispatchQueue.global().async {
                    if self.index == 0 {
                        self.api.deleteFavorite(boardID: boardID)
                    } else {
                        let _ = self.api.quitMemberOfBoard(boardID: boardID)
                    }
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop()
                        if self.api.errorCode == 0 {
                            SVProgressHUD.showSuccess(withStatus: "操作完成")
                            NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                            object: nil)
                        } else {
                            SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                        }
                    }
                }
            }
            actions.append(delFavAction)
        }
        return actions
    }
}
