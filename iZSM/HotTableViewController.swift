//
//  HotTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

struct SMHotSection {
    static let sections: [SMSection] = [
        SMSection(code: "", description: "[社区/站务]", name: "社区管理", id: 0),
        SMSection(code: "", description: "[学校/院系]", name: "国内院校", id: 1),
        SMSection(code: "", description: "[休闲/影音]", name: "休闲娱乐", id: 2),
        SMSection(code: "", description: "[地区/省份]", name: "五湖四海", id: 3),
        SMSection(code: "", description: "[游戏/运动]", name: "游戏运动", id: 4),
        SMSection(code: "", description: "[财经/信息]", name: "社会信息", id: 5),
        SMSection(code: "", description: "[谈天/生活]", name: "知性感性", id: 6),
        SMSection(code: "", description: "[社科/文学]", name: "文化人文", id: 7),
        SMSection(code: "", description: "[学科/技术]", name: "学术科学", id: 8),
        SMSection(code: "", description: "[专项/开发]", name: "电脑技术", id: 9)
    ]
    var id: Int
    var name: String
    var hotThreads: [SMHotThread]
}

class HotTableViewController: BaseTableViewController {
    
    private let kArticleCellIdentifier = "Article"
    
    var content: [SMHotSection] = [SMHotSection]() {
        didSet { tableView?.reloadData() }
    }
    
    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            let topTen = self.api.getHotThreadListInSection(section: 0) ?? [SMHotThread]()
            var content = [SMHotSection]()
            for sec in SMHotSection.sections {
                let hotThread = self.api.getHotThreadListInSection(section: sec.id + 1)
                content.append(SMHotSection(id: sec.id + 1, name: sec.name, hotThreads: hotThread ?? [SMHotThread]()))
            }
            content.sort { (leftSections, rightSections) -> Bool in
                let leftTotalCount = leftSections.hotThreads.reduce(0) { (partialCount, hotThread) -> Int in
                    partialCount + hotThread.count
                }
                let rightTotalCount = rightSections.hotThreads.reduce(0) { (partialCount, hotThread) -> Int in
                    partialCount + hotThread.count
                }
                return leftTotalCount > rightTotalCount
            }
            content.insert(SMHotSection(id: 0, name: "本日十大热门话题", hotThreads: topTen), at: 0)
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                self.tableView.mj_header.endRefreshing()
                SVProgressHUD.dismiss()
                self.content.removeAll()
                self.content += content
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    override func clearContent() {
        super.clearContent()
        content.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(HotTableViewCell.self, forCellReuseIdentifier: kArticleCellIdentifier)
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
    }
    
    // MARK: - Table view data source
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
        
        show(acvc, sender: self)
    }
}

extension HotTableViewController : UIViewControllerPreviewingDelegate {
    /// Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard
            let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let acvc = ArticleContentViewController()
        let thread = content[indexPath.section].hotThreads[indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true

        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return acvc
    }
    
    /// Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Reuse the "Peek" view controller for presentation.
        show(viewControllerToCommit, sender: self)
    }
}
