//
//  ArticleListSearchResultViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/10.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import SafariServices

class ArticleListSearchResultViewController: BaseTableViewController {
    
    private let kArticleListCellIdentifier = "ArticleListSearchResultCell"
    
    var boardID: String?
    var boardName: String?
    var userID: String?
    
    private var threadLoaded = 0
    private var threadRange: NSRange {
        return NSMakeRange(threadLoaded, setting.threadCountPerSection)
    }
    
    fileprivate var threads: [[SMThread]] = [[SMThread]]() {
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
    
    override func fetchMoreData() {
        if let boardID = self.boardID, let userID = self.userID {
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let threadSection = self.api.searchArticleInBoard(boardID: boardID,
                                                                  title: nil,
                                                                  user: userID,
                                                                  inRange: self.threadRange)
                DispatchQueue.main.async {
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
        tableView.mj_header.isHidden = true
        if let userID = userID, let boardName = boardName {
            title = "\(userID) 在 \(boardName) 版的大作"
        }
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
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
            readThread.flags = " " + flags.substring(from: flags.index(after: flags.startIndex))
            threads[indexPath.section][indexPath.row] = readThread
        }
        
        show(acvc, sender: self)
    }
}

extension ArticleListSearchResultViewController: UIViewControllerPreviewingDelegate, SmthViewControllerPreviewingDelegate {
    // MARK: UIViewControllerPreviewingDelegate
    
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard
            let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let acvc = ArticleContentViewController()
        let thread = threads[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.boardName = thread.boardName
        acvc.title = thread.subject
        acvc.previewDelegate = self
        acvc.hidesBottomBarWhenPushed = true
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return acvc
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let rect = previewingContext.sourceRect
        let center = CGPoint(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
        guard let indexPath = tableView.indexPathForRow(at: center) else { return }
        let thread = threads[indexPath.section][indexPath.row]
        
        if thread.flags.hasPrefix("*") {
            var readThread = thread
            let flags = thread.flags
            readThread.flags = " " + flags.substring(from: flags.index(after: flags.startIndex))
            threads[indexPath.section][indexPath.row] = readThread
        }
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }
    
    func previewActionItems(for viewController: UIViewController) -> [UIPreviewActionItem] {
        var actions = [UIPreviewActionItem]()
        if let acvc = viewController as? ArticleContentViewController {
            if let boardID = acvc.boardID, let articleID = acvc.articleID {
                let urlString: String
                switch self.setting.displayMode {
                case .nForum:
                    urlString = "https://www.newsmth.net/nForum/#!article/\(boardID)/\(articleID)"
                case .www2:
                    urlString = "https://www.newsmth.net/bbstcon.php?board=\(boardID)&gid=\(articleID)"
                case .mobile:
                    urlString = "https://m.newsmth.net/article/\(boardID)/\(articleID)"
                }
                let openAction = UIPreviewAction(title: "浏览网页版", style: .default) {[unowned self] (action, controller) in
                    let webViewController = SFSafariViewController(url: URL(string: urlString)!)
                    self.present(webViewController, animated: true, completion: nil)
                }
                actions.append(openAction)
                if let cell = cell(for: articleID, and: boardID) {
                    let shareAction = UIPreviewAction(title: "分享本帖", style: .default) { [unowned self] (action, controller) in
                        let title = "水木\(acvc.boardName ?? boardID)版：【\(acvc.title ?? "无标题")】"
                        let url = URL(string: urlString)!
                        let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                              applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = cell
                        activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    actions.append(shareAction)
                }
            }
        }
        return actions
    }
    
    private func cell(for articleID: Int, and boardID: String) -> UITableViewCell? {
        for section in 0..<threads.count {
            for row in 0..<threads[section].count {
                let thread = threads[section][row]
                if thread.id == articleID && thread.boardID == boardID {
                    return tableView.cellForRow(at: IndexPath(row: row, section: section))
                }
            }
        }
        return nil
    }
}

