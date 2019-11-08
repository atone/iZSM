//
//  MailBoxViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/23.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import SmthConnection

class MailBoxViewController: BaseTableViewController {
    
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(composeEmail(_:)))
    }
    
    override func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        let completion: SmthCompletion<[SMMail]> = { (result) in
            DispatchQueue.main.async {
                networkActivityIndicatorStop(withHUD: showHUD)
                completion?()
                switch result {
                case .success(let mails):
                    self.mailCountLoaded -= mails.count
                    self.mails.removeAll()
                    self.mails.append(mails.reversed())
                case .failure(let error):
                    error.display()
                }
            }
        }
        
        networkActivityIndicatorStart(withHUD: showHUD)
        if inbox {
            api.getMailCount { (result) in
                if let (totalCount, _, _) = try? result.get() {
                    self.mailCountLoaded = totalCount
                    self.api.getMailList(in: self.mailRange, completion: completion)
                }
            }
        } else {
            api.getMailCountSent { (result) in
                if let totalCount = try? result.get() {
                    self.mailCountLoaded = totalCount
                    self.api.getMailSentList(in: self.mailRange, completion: completion)
                }
            }
        }
    }
    
    override func fetchMoreData() {
        let completion: SmthCompletion<[SMMail]> = { (result) in
            DispatchQueue.main.async {
                networkActivityIndicatorStop()
                switch result {
                case .success(let mails):
                    self.mailCountLoaded -= mails.count
                    let indexPath = self.tableView.indexPathForSelectedRow
                    self.mails.append(mails.reversed())
                    if let indexPath = indexPath {
                        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                case .failure(let error):
                    error.display()
                }
            }
        }
        
        networkActivityIndicatorStart()
        if inbox {
            api.getMailList(in: mailRange, completion: completion)
        } else {
            api.getMailSentList(in: mailRange, completion: completion)
        }
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
    
    @objc private func composeEmail(_ sender: UIBarButtonItem) {
        let cec = ComposeEmailController()
        if !inbox {
            cec.completionHandler = { [unowned self] in
                self.fetchDataDirectly(showHUD: false)
            }
        }
        let navigationController = NTNavigationController(rootViewController: cec)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
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
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) // restore selection
            let allRead = mails.allSatisfy { $0.allSatisfy { !$0.flags.hasPrefix("N") } }
            if allRead {
                MessageCenter.shared.readAllMail()
            }
        }
        showDetailViewController(mcvc, sender: self)
    }
}
