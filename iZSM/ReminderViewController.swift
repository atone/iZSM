//
//  ReminderViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

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
        let mode: SMReference.ReferMode = replyMe ? .reply : .refer
        api.getReferCount(mode: mode) { (result) in
            if let (totalCount, _) = try? result.get() {
                self.referCountLoaded = totalCount
                self.api.getRefer(mode: mode, range: self.referRange) { (result) in
                    DispatchQueue.main.async {
                        networkActivityIndicatorStop(withHUD: showHUD)
                        completion?()
                        switch result {
                        case .success(let refers):
                            self.referCountLoaded -= refers.count
                            self.references.removeAll()
                            self.references.append(refers.reversed())
                        case .failure(let error):
                            error.display()
                        }
                    }
                }
            }
        }
    }
    
    override func fetchMoreData() {
        networkActivityIndicatorStart()
        let mode: SMReference.ReferMode = replyMe ? .reply : .refer
        api.getRefer(mode: mode, range: referRange) { (result) in
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                switch result {
                case .success(let refers):
                    self.referCountLoaded -= refers.count
                    self.references.append(refers.reversed())
                case .failure(let error):
                    error.display()
                }
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
            
            MessageCenter.shared.checkUnreadMessage()
        }
        showDetailViewController(rcvc, sender: self)
    }
}
