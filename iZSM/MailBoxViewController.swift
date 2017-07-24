//
//  MailBoxViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class MailBoxViewController: BaseTableViewController, ComposeEmailControllerDelegate {
    
    private let kMailListCellIdentifier = "MailListCell"
    
    var inbox: Bool = true {
        didSet {
            title = inbox ? "收件箱" : "发件箱"
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
        mails.removeAll()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(MailListCell.self, forCellReuseIdentifier: kMailListCellIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(composeEmail(sender:)))
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        networkActivityIndicatorStart(withHUD: showHUD)
        DispatchQueue.global().async {
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
            
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                if let fetchedMails = fetchedMails {
                    self.mailCountLoaded -= fetchedMails.count
                    self.mails.removeAll()
                    self.mails.append(fetchedMails.reversed())
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    override func fetchMoreData() {
        networkActivityIndicatorStart()
        DispatchQueue.global().async {
            var fetchedMails: [SMMail]?
            if self.inbox {
                fetchedMails = self.api.getMailList(inRange: self.mailRange)
            } else {
                fetchedMails = self.api.getMailSentList(inRange: self.mailRange)
            }
            
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                if let fetchedMails = fetchedMails {
                    self.mailCountLoaded -= fetchedMails.count
                    self.mails.append(fetchedMails.reversed())
                }
                self.api.displayErrorIfNeeded()
            }
        }
    }
    
    // ComposeEmailControllerDelegate
    func emailDidPosted() {
        fetchDataDirectly(showHUD: false)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return mails.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mails[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kMailListCellIdentifier, for: indexPath) as! MailListCell
        let mail = mails[indexPath.section][indexPath.row]
        // Configure the cell...
        cell.mail = mail
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if mails.isEmpty {
            return
        }
        if indexPath.section == mails.count - 1 && indexPath.row == mails[indexPath.section].count / 3 * 2 {
            if mailCountLoaded > 0 {
                fetchMoreData()
            }
        }
    }
    
    func composeEmail(sender: UIBarButtonItem) {
        let cec = ComposeEmailController()
        if !inbox {
            cec.delegate = self
        }
        let navigationController = NTNavigationController(rootViewController: cec)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mcvc = MailContentViewController()
        let mail = mails[indexPath.section][indexPath.row]
        mcvc.mail = mail
        mcvc.inbox = inbox
        if mail.flags.hasPrefix("N") {
            var readMail = mail
            readMail.flags = "  "
            mails[indexPath.section][indexPath.row] = readMail
            
            var allRead = true
            for section in 0..<mails.count {
                for row in 0..<mails[section].count {
                    if mails[section][row].flags.hasPrefix("N") {
                        allRead = false
                        break
                    }
                }
                if !allRead {
                    break
                }
            }
            if allRead {
                var unreadCount = UIApplication.shared.applicationIconBadgeNumber
                unreadCount = max(0, unreadCount - 1)
                if unreadCount > 0 {
                    self.tabBarItem?.badgeValue = "\(unreadCount)"
                } else {
                    self.tabBarItem?.badgeValue = nil
                }
                UIApplication.shared.applicationIconBadgeNumber = unreadCount
            }
        }
        show(mcvc, sender: self)
    }
}
