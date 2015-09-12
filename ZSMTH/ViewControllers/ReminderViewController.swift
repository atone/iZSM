//
//  ReminderViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class ReminderViewController: BaseTableViewController {
    @IBOutlet weak var segment: UISegmentedControl!

    var replyMe: Bool = true {
        didSet {
            segment?.selectedSegmentIndex = replyMe ? 0 : 1
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
        super.clearContent()
        references.removeAll()
    }

    @IBAction func segmentAction(sender: UISegmentedControl) {
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

    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
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
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                self.tableView.header.endRefreshing()
                if let fetchedRefers = fetchedRefers {
                    self.referCountLoaded -= fetchedRefers.count
                    self.references.removeAll()
                    self.references.append(Array(fetchedRefers.reverse()))
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }

    override func fetchMoreData() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var fetchedRefers: [SMReference]?
            if self.replyMe {
                fetchedRefers = self.api.getReferList(mode: .ReplyToMe, inRange: self.referRange)

            } else {
                fetchedRefers = self.api.getReferList(mode: .AtMe, inRange: self.referRange)
            }
            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                if let fetchedRefers = fetchedRefers {
                    self.referCountLoaded -= fetchedRefers.count
                    self.references.append(Array(fetchedRefers.reverse()))
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return references.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return references[section].count
    }

    private struct Static {
        static let ReminderListCellIdentifier = "ReminderListCell"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.ReminderListCellIdentifier, forIndexPath: indexPath) as! ReminderListCell
        let refer = references[indexPath.section][indexPath.row]
        // Configure the cell...
        cell.reference = refer
        return cell
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if references.isEmpty {
            return
        }
        if indexPath.section == references.count - 1 && indexPath.row == references[indexPath.section].count / 3 * 2 {
            if referCountLoaded > 0 {
                fetchMoreData()
            }
        }
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let
            rcvc = segue.destinationViewController as? ReferContentViewController,
            cell = sender as? UITableViewCell,
            indexPath = tableView.indexPathForCell(cell)
        {
            let reference = references[indexPath.section][indexPath.row]
            rcvc.reference = reference
            rcvc.replyMe = replyMe
            if reference.flag == 0 {
                var readReference = reference
                readReference.flag = 1
                references[indexPath.section][indexPath.row] = readReference
            }
        }
    }

}
