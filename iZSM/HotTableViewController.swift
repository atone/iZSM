//
//  HotTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class HotTableViewController: BaseTableViewController {
    
    private let kArticleCellIdentifier = "Article"
    
    let sections: [SMSection] = [
        SMSection(code: "", description: "", name: "本日十大热门话题", id: 0),
        SMSection(code: "", description: "", name: "国内院校", id: 2),
        SMSection(code: "", description: "", name: "休闲娱乐", id: 3),
        SMSection(code: "", description: "", name: "五湖四海", id: 4),
        SMSection(code: "", description: "", name: "游戏运动", id: 5),
        SMSection(code: "", description: "", name: "社会信息", id: 6),
        SMSection(code: "", description: "", name: "知性感性", id: 7),
        SMSection(code: "", description: "", name: "文化人文", id: 8),
        SMSection(code: "", description: "", name: "学术科学", id: 9),
        SMSection(code: "", description: "", name: "电脑技术", id: 10)
    ]
    
    var content: [[SMHotThread]] = [[SMHotThread]]() {
        didSet { tableView?.reloadData() }
    }
    
    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            var content = [[SMHotThread]]()
            for sec in self.sections {
                let hotThread = self.api.getHotThreadListInSection(section: sec.id)
                content.append(hotThread ?? [SMHotThread]())
            }
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
        return content[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return content[section].isEmpty ? nil : sections[section].name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kArticleCellIdentifier, for: indexPath) as! HotTableViewCell
        
        // Configure the cell...
        let hotThread = content[indexPath.section][indexPath.row]
        cell.hotThread = hotThread
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let acvc = ArticleContentViewController()
        let thread = content[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true
        
        if let result = ArticleReadStatusUtil.getStatus(boardID: thread.boardID, articleID: thread.id) {
            acvc.section = result.section
            acvc.row = result.row
        }
        
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
        let thread = content[indexPath.section][indexPath.row]
        acvc.articleID = thread.id
        acvc.boardID = thread.boardID
        acvc.title = thread.subject
        acvc.fromTopTen = true
        acvc.hidesBottomBarWhenPushed = true
        
        if let result = ArticleReadStatusUtil.getStatus(boardID: thread.boardID, articleID: thread.id) {
            acvc.section = result.section
            acvc.row = result.row
        }

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
