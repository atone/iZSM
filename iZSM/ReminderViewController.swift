//
//  ReminderViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class ReminderViewController: BaseTableViewController {

    private let kReminderListCellIdentifier = "ReminderListCell"
    
    var replyMe: Bool = true {
        didSet {
            title = replyMe ? "回复我" : "提到我"
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
    
    private var references: [[SMReference]] = [[SMReference]]() {
        didSet { tableView?.reloadData() }
    }
    
    override func clearContent() {
        references.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ReminderListCell.self, forCellReuseIdentifier: kReminderListCellIdentifier)
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        networkActivityIndicatorStart(withHUD: showHUD)
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
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                if let fetchedRefers = fetchedRefers {
                    self.referCountLoaded -= fetchedRefers.count
                    self.references.removeAll()
                    self.references.append(fetchedRefers.reversed())
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
                    self.references.append(fetchedRefers.reversed())
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
