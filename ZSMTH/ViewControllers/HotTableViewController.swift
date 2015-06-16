//
//  HotTableViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/6.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class HotTableViewController: BaseTableViewController {

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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var content = [[SMHotThread]]()
            for sec in self.sections {
                let hotThread = self.api.getHotThreadListInSection(sec.id)
                content.append(hotThread ?? [SMHotThread]())
            }
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                self.tableView.header.endRefreshing()
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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return content.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content[section].count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return content[section].isEmpty ? nil : sections[section].name
    }

    private struct Static {
        static let ArticleCellIdentifier = "Article"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.ArticleCellIdentifier, forIndexPath: indexPath) as! HotTableViewCell

        // Configure the cell...
        let hotThread = content[indexPath.section][indexPath.row]
        cell.hotThread = hotThread
        return cell
    }



    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var dvc = segue.destinationViewController as? UIViewController
        if let nvc = dvc as? UINavigationController {
            dvc = nvc.visibleViewController
        }

        if let
            acvc = dvc as? ArticleContentViewController,
            cell = sender as? UITableViewCell,
            indexPath = tableView.indexPathForCell(cell)
        {
            let thread = content[indexPath.section][indexPath.row]
            acvc.articleID = thread.id
            acvc.boardID = thread.boardID
            acvc.title = thread.subject
            acvc.fromTopTen = true
            acvc.hidesBottomBarWhenPushed = true
        }

    }


}
