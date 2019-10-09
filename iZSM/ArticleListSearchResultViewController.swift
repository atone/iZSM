//
//  ArticleListSearchResultViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/10.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class ArticleListSearchResultViewController: BaseTableViewController {
    
    private let kArticleListCellIdentifier = "ArticleListSearchResultCell"
    
    var boardID: String?
    var boardName: String?
    var userID: String?
    
    private var indexMap = [String : IndexPath]()
    
    private var threadLoaded = 0
    private var threadRange: NSRange {
        return NSMakeRange(threadLoaded, setting.threadCountPerSection)
    }
    
    private var threads: [[SMThread]] = [[SMThread]]() {
        didSet {
            tableView?.reloadData()
        }
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        if let boardID = self.boardID, let userID = self.userID {
            self.threadLoaded = 0
            networkActivityIndicatorStart(withHUD: showHUD)
            DispatchQueue.global().async {
                let threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                  title: nil,
                                                                  user: userID,
                                                                  inRange: self.threadRange)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: showHUD)
                    completion?()
                    self.threads.removeAll()
                    if let threadSection = threadSection {
                        self.threadLoaded += threadSection.count
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        } else {
            completion?()
        }
    }
    
    private var _isFetchingMoreData = false
    private var _semaphore = DispatchSemaphore(value: 1)
    
    override func fetchMoreData() {
        if let boardID = self.boardID, let userID = self.userID {
            
            _semaphore.wait()
            if !_isFetchingMoreData {
                _isFetchingMoreData = true
                _semaphore.signal()
            } else {
                _semaphore.signal()
                return
            }
            
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                  title: nil,
                                                                  user: userID,
                                                                  inRange: self.threadRange)
                DispatchQueue.main.async {
                    self._isFetchingMoreData = false
                    networkActivityIndicatorStop()
                    if let threadSection = threadSection {
                        self.threadLoaded += threadSection.count
                        self.threads.append(threadSection)
                    }
                    self.api.displayErrorIfNeeded()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ArticleListViewCell.self, forCellReuseIdentifier: kArticleListCellIdentifier)
        refreshHeaderEnabled = false
        if let userID = userID, let boardName = boardName {
            title = "\(userID) 在 \(boardName) 版的大作"
        }
    }
    
    override func clearContent() {
        threads.removeAll()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return threads.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads[section].count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if threads.isEmpty {
            return
        }
        if indexPath.section == threads.count - 1 && indexPath.row == threads[indexPath.section].count / 3 * 2 {
            fetchMoreData()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kArticleListCellIdentifier, for: indexPath) as! ArticleListViewCell
        cell.thread = threads[indexPath.section][indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acvc = ArticleContentViewController()
        let thread = threads[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.boardName = thread.boardName
        acvc.title = thread.subject
        acvc.hidesBottomBarWhenPushed = true
        if thread.flags.hasPrefix("*") {
            var readThread = thread
            let flags = thread.flags
            readThread.flags = " " + flags[flags.index(after: flags.startIndex)...]
            threads[indexPath.section][indexPath.row] = readThread
        }
        
        showDetailViewController(acvc, sender: self)
    }
}

extension ArticleListSearchResultViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let thread = threads[indexPath.section][indexPath.row]
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let urlString: String
        switch self.setting.displayMode {
        case .nForum:
            urlString = "https://www.newsmth.net/nForum/#!article/\(thread.boardID)/\(thread.id)"
        case .www2:
            urlString = "https://www.newsmth.net/bbstcon.php?board=\(thread.boardID)&gid=\(thread.id)"
        case .mobile:
            urlString = "https://m.newsmth.net/article/\(thread.boardID)/\(thread.id)"
        }
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: thread)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            let openAction = UIAction(title: "浏览网页版", image: UIImage(systemName: "safari")) { [unowned self] action in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            let starAction = UIAction(title: "收藏本帖", image: UIImage(systemName: "star")) { [unowned self] action in
                let alertController = UIAlertController(title: "备注", message: nil, preferredStyle: .alert)
                alertController.addTextField { textField in
                    textField.placeholder = "备注信息（可选）"
                    textField.returnKeyType = .done
                }
                let okAction = UIAlertAction(title: "确定", style: .default) { [unowned alertController] _ in
                    if let textField = alertController.textFields?.first {
                        var comment: String? = nil
                        if let text = textField.text, text.count > 0 {
                            comment = text
                        }
                        networkActivityIndicatorStart(withHUD: true)
                        StarThread.updateInfo(articleID: thread.id, boardID: thread.boardID, comment: comment) { success in
                            networkActivityIndicatorStop(withHUD: true)
                            if success {
                                SVProgressHUD.showSuccess(withStatus: "收藏成功")
                            } else {
                                SVProgressHUD.showInfo(withStatus: "收藏失败")
                            }
                        }
                    }
                }
                alertController.addAction(okAction)
                alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                self.present(alertController, animated: true)
            }
            let shareAction = UIAction(title: "分享本帖", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] action in
                let title = "水木\(thread.boardName)版：【\(thread.subject)】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = cell
                activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                self.present(activityViewController, animated: true)
            }
            return UIMenu(title: "", children: [openAction, starAction, shareAction])
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            let thread = self.threads[indexPath.section][indexPath.row]
            if thread.flags.hasPrefix("*") {
                var readThread = thread
                let flags = thread.flags
                readThread.flags = " " + flags.dropFirst()
                self.threads[indexPath.section][indexPath.row] = readThread
            }
            let acvc = self.getViewController(with: thread)
            self.showDetailViewController(acvc, sender: self)
        }
    }
    
    private func getViewController(with thread: SMThread) -> ArticleContentViewController {
        let acvc = ArticleContentViewController()
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.boardName = thread.boardName
        acvc.title = thread.subject
        acvc.hidesBottomBarWhenPushed = true
        return acvc
    }
}
