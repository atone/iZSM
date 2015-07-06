//
//  MailBoxViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/19.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class MailBoxViewController: BaseTableViewController, ComposeEmailControllerDelegate {
    @IBOutlet weak var segment: UISegmentedControl!

    var inbox: Bool = true {
        didSet {
            segment?.selectedSegmentIndex = inbox ? 0 : 1
        }
    }

    private var mailCountLoaded = 0
    private let mailCountPerSection = 20

    private var mailRange: NSRange {
        if mailCountLoaded - mailCountPerSection > 0 {
            return NSMakeRange(mailCountLoaded - mailCountPerSection, mailCountPerSection)
        } else {
            return NSMakeRange(0, mailCountLoaded)
        }
    }

    private var mails: [[SMMail]] = [[SMMail]]() {
        didSet { tableView?.reloadData() }
    }

    override func clearContent() {
        super.clearContent()
        mails.removeAll()
    }

    @IBAction func segmentAction(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            inbox = true
            fetchData()
        case 1:
            inbox = false
            fetchData()
        default:
            break
        }
    }


    override func fetchDataDirectly() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var fetchedMails: [SMMail]?
            if self.inbox {
                if let status = self.api.getMailStatus() {
                    self.mailCountLoaded = status.totalCount
                    fetchedMails = self.api.getMailList(inRange: self.mailRange)
                }
            } else {
                self.mailCountLoaded = self.api.getMailSentCount()
                fetchedMails = self.api.getMailSentList(inRange: self.mailRange)
            }

            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.header.endRefreshing()
                networkActivityIndicatorStop()
                if let fetchedMails = fetchedMails {
                    self.mailCountLoaded -= fetchedMails.count
                    self.mails.removeAll()
                    self.mails.append(fetchedMails.reverse())
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }

    override func fetchMoreData() {
        networkActivityIndicatorStart()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            var fetchedMails: [SMMail]?
            if self.inbox {
                fetchedMails = self.api.getMailList(inRange: self.mailRange)
            } else {
                fetchedMails = self.api.getMailSentList(inRange: self.mailRange)
            }

            dispatch_async(dispatch_get_main_queue()) {
                networkActivityIndicatorStop()
                if let fetchedMails = fetchedMails {
                    self.mailCountLoaded -= fetchedMails.count
                    self.mails.append(fetchedMails.reverse())
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }

    // ComposeEmailControllerDelegate
    func emailDidPosted() {
        fetchDataDirectly()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return mails.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mails[section].count
    }

    private struct Static {
        static let MailListCellIdentifier = "MailListCell"
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Static.MailListCellIdentifier, forIndexPath: indexPath) as! MailListCell
        let mail = mails[indexPath.section][indexPath.row]
        // Configure the cell...
        cell.mail = mail
        return cell
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if mails.isEmpty {
            return
        }
        if indexPath.section == mails.count - 1 && indexPath.row == mails[indexPath.section].count / 3 * 2 {
            if mailCountLoaded > 0 {
                fetchMoreData()
            }
        }
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let
            mcvc = segue.destinationViewController as? MailContentViewController,
            cell = sender as? UITableViewCell,
            indexPath = tableView.indexPathForCell(cell)
        {
            let mail = mails[indexPath.section][indexPath.row]
            mcvc.mail = mail
            mcvc.inbox = inbox
            if mail.flags.hasPrefix("N") {
                var readMail = mail
                readMail.flags = "  "
                mails[indexPath.section][indexPath.row] = readMail
            }
        } else {
            var dvc = segue.destinationViewController as? UIViewController
            if let nvc = dvc as? UINavigationController {
                dvc = nvc.visibleViewController
            }
            if let cec = dvc as? ComposeEmailController {
                if !inbox {
                    cec.delegate = self
                }
            }

        }
    }


}
