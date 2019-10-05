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
        let switcher = UISegmentedControl(items: ["版面收藏", "驻版"])
        switcher.selectedSegmentIndex = 0
        switcher.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        switcher.addTarget(self, action: #selector(indexChanged(_:)), for: .valueChanged)
        return switcher
    }()
    
    var index: Int = 0 {
        didSet {
            if switcher.selectedSegmentIndex != index {
                switcher.selectedSegmentIndex = index
            }
        }
    }
    
    private var indexMap = [String : IndexPath]()
    
    var groupID: Int = 0
    private var favorites = [SMBoard]()
    
    override func clearContent() {
        favorites.removeAll()
        tableView?.reloadData()
    }
    
    @objc private func setUpdateFavList(_ notification: Notification) {
        fetchData(showHUD: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var barButtonItems = [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFavoriteAction(_:)))]
        if groupID == 0 { //只有根目录下有进入文章收藏的入口，以及切换收藏夹和驻版的Switcher
            barButtonItems.append(UIBarButtonItem(image: UIImage(systemName: "text.badge.star"), style: .plain, target: self, action: #selector(showStarThreadVC(_:))))
            navigationItem.titleView = switcher
            navigationItem.leftBarButtonItem = editButtonItem
        }
        navigationItem.rightBarButtonItems = barButtonItems
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setUpdateFavList(_:)),
                                               name: FavListViewController.kUpdateFavListNotification,
                                               object: nil)
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
                let ret = self.api.getFavBoardList(group: self.groupID) ?? [SMBoard]()
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
                SMBoardInfo.save(boardList: favBoards)
            }
        }
    }
    
    @objc private func indexChanged(_ sender: UISegmentedControl) {
        index = sender.selectedSegmentIndex
        fetchDataDirectly(showHUD: true)
    }
    
    @objc private func showStarThreadVC(_ sender: UIBarButtonItem) {
        let vc = StarThreadViewController(style: .plain)
        vc.hidesBottomBarWhenPushed = true
        show(vc, sender: self)
    }
    
    @objc private func addFavoriteAction(_ sender: UIBarButtonItem) {
        if index == 0 {
            let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let addBoardAction = UIAlertAction(title: "收藏版面", style: .default) { [unowned self] _ in
                self.addFavorite()
            }
            sheet.addAction(addBoardAction)
            let addDirectoryAction = UIAlertAction(title: "新建目录", style: .default) { [unowned self] _ in
                self.addFavoriteDirectory()
            }
            sheet.addAction(addDirectoryAction)
            sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            present(sheet, animated: true)
        } else {
            addFavorite()
        }
    }
    
    func addFavoriteDirectory() {
        let alert = UIAlertController(title: "目录名称", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "确定", style: .default) { [unowned self] _ in
            if let name = alert.textFields?.first?.text, name.count > 0 {
                self.addFavoriteDirectoryWithName(name)
            }
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func addFavorite() {
        let title = "请选择要\(self.index == 0 ? "收藏" : "关注")的版面"
        let searchResultController = BoardListSearchResultViewController.searchResultController(title: title) { [unowned self] (controller, board) in
            let confirmAlert = UIAlertController(title: "确认\(self.index == 0 ? "收藏" : "关注")?", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "确认", style: .default) { [unowned self] _ in
                self.dismiss(animated: true)
                self.addFavoriteWithBoardID(board.boardID)
            }
            confirmAlert.addAction(okAction)
            confirmAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            controller.present(confirmAlert, animated: true)
        }
        searchResultController.modalPresentationStyle = .formSheet
        present(searchResultController, animated: true)
    }
    
    func addFavoriteDirectoryWithName(_ name: String) {
        guard let user = setting.username, let pass = setting.password else { return }
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            let success = self.api.addFavoriteDirectory(name, in: self.groupID, user: user, pass: pass)
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                if success {
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                    object: nil)
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
            }
        }
    }
    
    func addFavoriteWithBoardID(_ boardID: String) {
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            var joinResult = 0
            if self.index == 0 {
                self.api.addFavorite(boardID: boardID, group: self.groupID)
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
                cell.accessoryView = UIImageView(image: UIImage(systemName: "folder"))
                cell.accessoryView?.tintColor = UIColor.secondaryLabel
            }
        }
        // Configure the cell...
        cell.textLabel?.text = fav.name
        cell.detailTextLabel?.text = fav.boardID
        let titleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline)
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: titleDescr.pointSize * setting.fontScale)
        let subtitleDescr = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .subheadline)
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: subtitleDescr.pointSize * setting.fontScale)
        cell.textLabel?.textColor = UIColor(named: "MainText")
        cell.detailTextLabel?.textColor = UIColor.secondaryLabel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let board = favorites[indexPath.row]
        if board.bid < 0 || board.position < 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let flvc = FavListViewController()
            flvc.title = board.name
            flvc.groupID = board.bid
            show(flvc, sender: self)
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
        let board = favorites[indexPath.row]
        if board.bid < 0 || board.position < 0 {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        guard let user = setting.username, let pass = setting.password else { return }
        let fav = favorites[indexPath.row]
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            if (fav.flag != -1) && (fav.flag & 0x400 == 0) { //版面
                if self.index == 0 {
                    self.api.delFavorite(boardID: fav.boardID, group: self.groupID)
                } else {
                    let _ = self.api.quitMemberOfBoard(boardID: fav.boardID)
                }
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if self.api.errorCode == 0 {
                        NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                        object: nil)
                    } else {
                        SVProgressHUD.showInfo(withStatus: self.api.errorDescription)
                    }
                }
            } else { //目录
                let success = self.api.delFavoriteDirectory(fav.position, in: self.groupID, user: user, pass: pass)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if success {
                        NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                        object: nil)
                    }
                }
            }
        }
    }
}

extension FavListViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let board = favorites[indexPath.row]
        if board.bid < 0 || board.position < 0 {
            return nil
        }
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: board)
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: nil)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            let board = self.favorites[indexPath.row]
            let vc = self.getViewController(with: board)
            self.show(vc, sender: self)
        }
    }
    
    private func getViewController(with board: SMBoard) -> BaseTableViewController {
        if board.flag == -1 || (board.flag > 0 && board.flag & 0x400 != 0) {
            let flvc = FavListViewController()
            flvc.title = board.name
            flvc.groupID = board.bid
            return flvc
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
