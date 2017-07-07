//
//  ReminderViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SVProgressHUD

class ReminderViewController: BaseTableViewController {

    private let kReminderListCellIdentifier = "ReminderListCell"
    var segment: UISegmentedControl = UISegmentedControl(items: ["回复我", "提到我"])
    
    var replyMe: Bool = true {
        didSet {
            segment.selectedSegmentIndex = replyMe ? 0 : 1
        }
    }
    
    private var referCountLoaded: Int = 0
    private var referCountPerSection = 20
    private var referRange: NSRange {
        if referCountLoaded - referCountPerSection >= 0 {
            return NSMakeRange(referCountLoaded - referCountPerSection, referCountPerSection)
        } else {
            return NSMakeRange(0, referCountLoaded)
        }
    }
    
    private var references: [[SMReference]] = [[SMReference]]()
    
    override func clearContent() {
        super.clearContent()
        references.removeAll()
    }
    
    func segmentAction(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            replyMe = true
            fetchData()
        case 1:
            replyMe = false
            fetchData()
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ReminderListCell.self, forCellReuseIdentifier: kReminderListCellIdentifier)
        segment.addTarget(self, action: #selector(segmentAction(sender:)), for: .valueChanged)
        segment.setWidth(100, forSegmentAt: 0)
        segment.setWidth(100, forSegmentAt: 1)
        navigationItem.titleView = segment
    }
    
    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            var fetchedRefers: [SMReference]?
            if self.replyMe {
                if let status = self.api.getReferCount(mode: .ReplyToMe) {
                    self.referCountLoaded = status.totalCount
                    fetchedRefers = self.api.getReferList(mode: .ReplyToMe, inRange: self.referRange)
                }
                
            } else {
                if let status = self.api.getReferCount(mode: .AtMe) {
                    self.referCountLoaded = status.totalCount
                    fetchedRefers = self.api.getReferList(mode: .AtMe, inRange: self.referRange)
                }
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                self.tableView.mj_header.endRefreshing()
                SVProgressHUD.dismiss()
                if let fetchedRefers = fetchedRefers {
                    self.referCountLoaded -= fetchedRefers.count
                    self.references.removeAll()
                    self.references.append(Array(fetchedRefers.reversed()))
                    self.tableView.reloadData()
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    override func fetchMoreData() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            var fetchedRefers: [SMReference]?
            if self.replyMe {
                fetchedRefers = self.api.getReferList(mode: .ReplyToMe, inRange: self.referRange)
                
            } else {
                fetchedRefers = self.api.getReferList(mode: .AtMe, inRange: self.referRange)
            }
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if let fetchedRefers = fetchedRefers {
                    self.referCountLoaded -= fetchedRefers.count
                    self.references.append(Array(fetchedRefers.reversed()))
                    self.tableView.reloadData()
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return references.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return references[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReminderListCellIdentifier, for: indexPath) as! ReminderListCell
        let refer = references[indexPath.section][indexPath.row]
        // Configure the cell...
        cell.reference = refer
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if references.isEmpty {
            return
        }
        if indexPath.section == references.count - 1 && indexPath.row == references[indexPath.section].count / 3 * 2 {
            if referCountLoaded > 0 {
                fetchMoreData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rcvc = ReferContentViewController()
        let reference = references[indexPath.section][indexPath.row]
        rcvc.reference = reference
        rcvc.replyMe = replyMe
        if reference.flag == 0 {
            var readReference = reference
            readReference.flag = 1
            references[indexPath.section][indexPath.row] = readReference
        }
        show(rcvc, sender: self)
    }
}
