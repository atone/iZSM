//
//  FavListViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/22.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import SmthConnection

class FavListViewController: BaseTableViewController, FavoriteAddable {
    static let kUpdateFavListNotification = Notification.Name("UpdateFavListNotification")
    private let kBoardIdentifier = "Board"
    private let kDirectoryIdentifier = "Directory"
    private let kStarThreadIdentifier = "StarThread"
    
    private let container = CoreDataHelper.shared.persistentContainer
    
    private lazy var fetchedResultsController: NSFetchedResultsController<StarThread> = {
        let request: NSFetchRequest<StarThread> = StarThread.fetchRequest()
        let userID = AppSetting.shared.username!.lowercased()
        request.predicate = NSPredicate(format: "userID == '\(userID)'")
        request.sortDescriptors = [NSSortDescriptor(key: "createTime", ascending: false)]
        let frc = NSFetchedResultsController<StarThread>(fetchRequest: request,
                                                         managedObjectContext: container.viewContext,
                                                         sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try? frc.performFetch()
        return frc
    }()
    
    private lazy var addItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFavoriteAction(_:)))
    }()
    
    private lazy var switcher: UISegmentedControl = {
        let switcher = UISegmentedControl(items: ["版面收藏", "文章收藏"])
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
        if let userInfo = notification.userInfo,
            let groupID = userInfo["group_id"] as? Int, groupID == self.groupID {
            fetchData(showHUD: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(StarThreadViewCell.self, forCellReuseIdentifier: kStarThreadIdentifier)
        navigationItem.rightBarButtonItem = addItem
        if groupID == 0 { //只有根目录下有进入文章收藏的入口，以及切换版面收藏和文章收藏的Switcher
            navigationItem.titleView = switcher
            navigationItem.leftBarButtonItem = editButtonItem
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(setUpdateFavList(_:)),
                                               name: FavListViewController.kUpdateFavListNotification,
                                               object: nil)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        networkActivityIndicatorStart(withHUD: showHUD)
        api.getFavoriteList(in: groupID) { (result) in
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                self.favorites.removeAll()
                switch result {
                case .success(let favBoards):
                    self.favorites += favBoards
                    SMBoardInfo.save(boardList: favBoards)
                case .failure(let error):
                    error.display()
                }
                if self.index == 0 {
                    self.tableView?.reloadData()
                }
            }
        }
    }
    
    @objc private func indexChanged(_ sender: UISegmentedControl) {
        index = sender.selectedSegmentIndex
        if index == 0 {
            refreshHeaderEnabled = true
            navigationItem.rightBarButtonItem = addItem
        } else {
            refreshHeaderEnabled = false
            navigationItem.rightBarButtonItem = nil
        }
        tableView?.reloadData()
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
            sheet.popoverPresentationController?.barButtonItem = sender
            present(sheet, animated: true)
        }
    }
    
    func addFavoriteDirectory() {
        let alert = UIAlertController(title: "目录名称", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "确定", style: .default) { [unowned self] _ in
            if let name = alert.textFields?.first?.text, name.count > 0 {
                self.addFavoriteDirectoryWithName(name, in: self.groupID)
            }
        }
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    func addFavorite() {
        let searchResultController = BoardListSearchResultViewController.searchResultController(title: "请选择要收藏的版面") { [unowned self] (controller, board) in
            let confirmAlert = UIAlertController(title: "确认收藏?", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "确认", style: .default) { [unowned self] _ in
                self.dismiss(animated: true)
                self.addFavoriteWithBoardID(board.boardID, in: self.groupID)
            }
            confirmAlert.addAction(okAction)
            confirmAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            controller.present(confirmAlert, animated: true)
        }
        searchResultController.modalPresentationStyle = .formSheet
        present(searchResultController, animated: true)
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.index == 0 {
            return favorites.count
        } else {
            if let sections = fetchedResultsController.sections {
                return sections[section].numberOfObjects
            }
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.index == 0 {
            return getFavoriteCell(for: tableView, at: indexPath)
        } else {
            return getStarThreadCell(for: tableView, at: indexPath)
        }
    }
    
    private func getFavoriteCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
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
    
    private func getStarThreadCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kStarThreadIdentifier, for: indexPath) as! StarThreadViewCell
        let object = fetchedResultsController.object(at: indexPath)
        cell.configure(with: object)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.index == 0 {
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
        } else {
            let object = fetchedResultsController.object(at: indexPath)
            let context = fetchedResultsController.managedObjectContext
            object.accessTime = Date()
            try? context.save()
            let acvc = ArticleContentViewController()
            acvc.articleID = Int(object.articleID)
            acvc.boardID = object.boardID
            acvc.fromStar = true
            acvc.title = object.articleTitle
            acvc.hidesBottomBarWhenPushed = true
            showDetailViewController(acvc, sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.index == 0 {
            let board = favorites[indexPath.row]
            if board.bid < 0 || board.position < 0 {
                return false
            }
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        if self.index == 0 {
            deleteFavoriteItem(at: indexPath)
        } else {
            deleteStarThread(at: indexPath)
        }
    }
    
    private func deleteFavoriteItem(at indexPath: IndexPath) {
        guard let user = setting.username, let pass = setting.password else { return }
        let fav = favorites[indexPath.row]
        networkActivityIndicatorStart()
        if (fav.flag != -1) && (fav.flag & 0x400 == 0) { //版面
            api.delFavorite(fav.boardID, in: groupID) { result in
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    switch result {
                    case .success:
                        NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                        object: nil, userInfo: ["group_id": self.groupID])
                    case .failure(let error):
                        error.display()
                    }
                }
            }
        } else { //目录
            DispatchQueue.global().async {
                let success = self.api.delFavoriteDirectory(fav.position, in: self.groupID, user: user, pass: pass)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if success {
                        NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                        object: nil, userInfo: ["group_id": self.groupID])
                    }
                }
            }
        }
    }
    
    private func deleteStarThread(at indexPath: IndexPath) {
        let object = fetchedResultsController.object(at: indexPath)
        let context = fetchedResultsController.managedObjectContext
        context.delete(object)
        try? context.save()
    }
}

extension FavListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard self.index == 1 else { return }
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard self.index == 1 else { return }
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        guard self.index == 1 else { return }
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard self.index == 1 else { return }
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                if let cell = cell as? StarThreadViewCell {
                    let object = fetchedResultsController.object(at: indexPath)
                    cell.configure(with: object)
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        @unknown default:
            break
        }
    }
}

extension FavListViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !setting.disableHapticTouch else { return nil }
        if self.index == 0 {
            return favoriteContextMenuConfiguration(at: indexPath)
        } else {
            return starThreadContextMenuConfiguration(for: tableView, at: indexPath)
        }
    }
    
    private func favoriteContextMenuConfiguration(at indexPath: IndexPath) -> UIContextMenuConfiguration? {
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
    
    private func starThreadContextMenuConfiguration(for tableView: UITableView, at indexPath: IndexPath) -> UIContextMenuConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let thread = self.fetchedResultsController.object(at: indexPath)
        guard let boardID = thread.boardID, let articleTitle = thread.articleTitle else { return nil }
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let urlString: String
        switch AppSetting.shared.displayMode {
        case .nForum:
            urlString = setting.httpPrefix + "www.mysmth.net/nForum/#!article/\(boardID)/\(thread.articleID)"
        case .www2:
            urlString = setting.httpPrefix + "www.mysmth.net/bbstcon.php?board=\(boardID)&gid=\(thread.articleID)"
        case .mobile:
            urlString = setting.httpPrefix + "m.mysmth.net/article/\(boardID)/\(thread.articleID)"
        }
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: thread)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            let openAction = UIAction(title: "浏览网页版", image: UIImage(systemName: "safari")) { [unowned self] action in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            let shareAction = UIAction(title: "分享本帖", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] action in
                let title = "水木\(boardID)版：【\(articleTitle)】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = cell
                activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                self.present(activityViewController, animated: true)
            }
            return UIMenu(title: "", children: [openAction, shareAction])
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            if self.index == 0 {
                let board = self.favorites[indexPath.row]
                let vc = self.getViewController(with: board)
                self.show(vc, sender: self)
            } else {
                let thread = self.fetchedResultsController.object(at: indexPath)
                thread.accessTime = Date()
                try? self.fetchedResultsController.managedObjectContext.save()
                let acvc = self.getViewController(with: thread)
                self.showDetailViewController(acvc, sender: self)
            }
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
    
    private func getViewController(with thread: StarThread) -> ArticleContentViewController {
        let acvc = ArticleContentViewController()
        acvc.articleID = Int(thread.articleID)
        acvc.boardID = thread.boardID
        acvc.fromStar = true
        acvc.title = thread.articleTitle
        acvc.hidesBottomBarWhenPushed = true
        return acvc
    }
}

protocol FavoriteAddable {
    var api: SmthAPI { get }
    var setting: AppSetting { get }
    
    func addFavoriteWithBoardID(_ boardID: String, in group: Int) -> Void
    func addFavoriteDirectoryWithName(_ name: String, in group: Int) -> Void
}

extension FavoriteAddable {
    func addFavoriteDirectoryWithName(_ name: String, in group: Int) {
        guard let user = setting.username, let pass = setting.password else { return }
        networkActivityIndicatorStart(withHUD: true)
        DispatchQueue.global().async {
            let success = self.api.addFavoriteDirectory(name, in: group, user: user, pass: pass)
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                if success {
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil, userInfo: ["group_id": group])
                } else {
                    SVProgressHUD.showError(withStatus: "出错了")
                }
            }
        }
    }
    
    func addFavoriteWithBoardID(_ boardID: String, in group: Int) {
        networkActivityIndicatorStart(withHUD: true)
        api.addFavorite(boardID, in: group) { result in
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: true)
                switch result {
                case .success:
                    SVProgressHUD.showSuccess(withStatus: "添加成功")
                    NotificationCenter.default.post(name: FavListViewController.kUpdateFavListNotification,
                                                    object: nil, userInfo: ["group_id": group])
                case .failure(let error):
                    if error.code == 10319 {
                        SVProgressHUD.showInfo(withStatus: "该版面已在收藏夹中")
                    } else {
                        error.display()
                    }
                }
            }
        }
    }
}
