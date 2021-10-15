//
//  HotTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD
import SmthConnection

struct SMHotSection {
    static let sections: [SMSection] = [
        SMSection(id: 0, name: "社区管理", description: "[社区/站务]"),
        SMSection(id: 1, name: "国内院校", description: "[学校/院系]"),
        SMSection(id: 2, name: "休闲娱乐", description: "[休闲/影音]"),
        SMSection(id: 3, name: "五湖四海", description: "[地区/省份]"),
        SMSection(id: 4, name: "游戏运动", description: "[游戏/运动]"),
        SMSection(id: 5, name: "社会信息", description: "[财经/信息]"),
        SMSection(id: 6, name: "知性感性", description: "[谈天/生活]"),
        SMSection(id: 7, name: "文化人文", description: "[社科/文学]"),
        SMSection(id: 8, name: "学术科学", description: "[学科/技术]"),
        SMSection(id: 9, name: "电脑技术", description: "[专项/开发]")
    ]
    var id: Int
    var name: String
    var hotThreads: [SMHotThread]
}

class HotTableViewController: BaseTableViewController {
    
    private let kArticleCellIdentifier = "Article"
    static let kUpdateHotSectionNotification = Notification.Name("UpdateHotSectionNotification")
    
    var content = [SMHotSection]() {
        didSet { tableView?.reloadData() }
    }
    
    private var indexMap = [String : IndexPath]()
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        networkActivityIndicatorStart(withHUD: showHUD)
        DispatchQueue.global().async {
            do {
                let comparator: (SMHotSection, SMHotSection) -> Bool = {
                    (left, right) -> Bool in
                    let leftCount = left.hotThreads.reduce(0) { (partial, thread) -> Int in
                        partial + thread.count
                    }
                    let rightCount = right.hotThreads.reduce(0) { (partial, thread) -> Int in
                        partial + thread.count
                    }
                    return leftCount > rightCount
                }
                let topTen = try self.api.getHotThreadList(in: 0)
                var content = [SMHotSection]()
                if !self.setting.customHotSection {
                    for sec in SMHotSection.sections {
                        let threads = try self.api.getHotThreadList(in: sec.id + 1)
                        if threads.count > 0 {
                            content.append(SMHotSection(id: sec.id + 1, name: sec.name, hotThreads: threads))
                        }
                    }
                    content.sort(by: comparator)
                } else {
                    for secID in self.setting.availableHotSections {
                        let sec = SMHotSection.sections[secID]
                        let threads = try self.api.getHotThreadList(in: sec.id + 1)
                        if threads.count > 0 {
                            content.append(SMHotSection(id: sec.id + 1, name: sec.name, hotThreads: threads))
                        }
                    }
                    if self.setting.autoSortHotSection {
                        content.sort(by: comparator)
                    }
                }
                content.insert(SMHotSection(id: 0, name: "本日十大热门话题", hotThreads: topTen), at: 0)
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: showHUD)
                    completion?()
                    self.content = content
                }
            } catch {
                DispatchQueue.main.async {
                    networkActivityIndicatorStop(withHUD: showHUD)
                    completion?()
                    self.content = []
                    (error as? SMError)?.display()
                }
            }
        }
    }
    
    override func clearContent() {
        content.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HotTableViewCell.self, forCellReuseIdentifier: kArticleCellIdentifier)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateHotSection(_:)),
                                               name: HotTableViewController.kUpdateHotSectionNotification,
                                               object: nil)
    }
    
    @objc private func updateHotSection(_ notification: Notification) {
        fetchData(showHUD: false)
    }
    
    // MARK: - Table view data source and delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return content.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content[section].hotThreads.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return content[section].name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kArticleCellIdentifier, for: indexPath) as! HotTableViewCell
        
        // Configure the cell...
        let hotThread = content[indexPath.section].hotThreads[indexPath.row]
        cell.hotThread = hotThread
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acvc = ArticleContentViewController()
        let thread = content[indexPath.section].hotThreads[indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true
        
        showDetailViewController(acvc, sender: self)
    }
}

extension HotTableViewController {
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !setting.disableHapticTouch else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let thread = self.content[indexPath.section].hotThreads[indexPath.row]
        let identifier = NSUUID().uuidString
        indexMap[identifier] = indexPath
        let urlString: String
        switch self.setting.displayMode {
        case .nForum:
            urlString = setting.httpPrefix + "www.mysmth.net/nForum/#!article/\(thread.boardID)/\(thread.id)"
        case .www2:
            urlString = setting.httpPrefix + "www.mysmth.net/bbstcon.php?board=\(thread.boardID)&gid=\(thread.id)"
        case .mobile:
            urlString = setting.httpPrefix + "m.mysmth.net/article/\(thread.boardID)/\(thread.id)"
        }
        let preview: UIContextMenuContentPreviewProvider = { [unowned self] in
            self.getViewController(with: thread)
        }
        let actions: UIContextMenuActionProvider = { [unowned self] seggestedActions in
            let shareAction = UIAction(title: "分享本帖", image: UIImage(systemName: "square.and.arrow.up")) { [unowned self] action in
                let title = "水木\(thread.boardID)版：【\(thread.subject)】"
                let url = URL(string: urlString)!
                let activityViewController = UIActivityViewController(activityItems: [title, url],
                                                                      applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = cell
                activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                self.present(activityViewController, animated: true)
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
            let openAction = UIAction(title: "浏览网页版", image: UIImage(systemName: "safari")) { [unowned self] action in
                let webViewController = NTSafariViewController(url: URL(string: urlString)!)
                self.present(webViewController, animated: true)
            }
            let gotoBoardAction = UIAction(title: "进入 \(thread.boardID) 版", image: UIImage(systemName: "list.bullet")) { [unowned self] action in
                let alvc = ArticleListViewController()
                alvc.boardID = thread.boardID
                alvc.boardName = thread.boardID
                alvc.hidesBottomBarWhenPushed = true
                self.show(alvc, sender: self)
            }
            return UIMenu(title: "", children: [shareAction, starAction, openAction, gotoBoardAction])
        }
        return UIContextMenuConfiguration(identifier: identifier as NSString, previewProvider: preview, actionProvider: actions)
    }
    
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion { [unowned self] in
            guard let identifier = configuration.identifier as? String else { return }
            guard let indexPath = self.indexMap[identifier] else { return }
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            let thread = self.content[indexPath.section].hotThreads[indexPath.row]
            let acvc = self.getViewController(with: thread)
            self.showDetailViewController(acvc, sender: self)
        }
    }
    
    private func getViewController(with thread: SMHotThread) -> ArticleContentViewController {
        let acvc = ArticleContentViewController()
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true
        return acvc
    }
}

extension HotTableViewController {
    func navigateRefresh() {
        fetchDataDirectly(showHUD: true) {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}
