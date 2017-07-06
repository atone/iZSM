//
//  BaseTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    let api = SmthAPI()
    let setting = AppSetting.sharedSetting
    
    var needRefresh = true
    
    // subclass need override this and add clear content
    func clearContent() {
        needRefresh = true
    }
    
    func fetchMoreData() {
        // fetch more data as user scroll up
        fatalError("fetchMoreData() Not implemented")
    }
    
    func fetchDataDirectly() {
        // subclass must override this method to fetch initial data
        // without check login status
        fatalError("fetchDataDirectly() Not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableview self-sizing cell
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(notification:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        tableView.tableFooterView = footerView
        let header = MJRefreshNormalHeader(refreshingTarget: self,
                                           refreshingAction: #selector(fetchData))
        header?.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = header
    }
    
    // check login status and fetch initial data
    func fetchData() {
        if let accessToken = setting.accessToken { // fetch data directly
            api.accessToken = accessToken
            fetchDataDirectly()
        } else if let username = setting.username, let password = setting.password { // silent login
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let loginSuccess = self.api.loginBBS(username: username, password: password) == 0 ? false : true
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if loginSuccess && self.api.errorCode == 0 {
                        self.setting.accessToken = self.api.accessToken
                        self.fetchDataDirectly()
                    } else {
                        self.tableView.mj_header.endRefreshing()
                        self.api.displayErrorIfNeeded()
                    }
                }
            }
            
        } else { // present login view controller
            let loginViewController = LoginViewController()
            loginViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: loginViewController)
            let rootvc = UIApplication.shared.keyWindow?.rootViewController
            rootvc?.present(navigationController, animated: false, completion: nil)
        }
    }
    
    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // refresh when needed
        if needRefresh {
            fetchData()
            needRefresh = false
        }
    }
    
    // handle font size change
    func preferredFontSizeChanged(notification: Notification) {
        tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        needRefresh = true
        super.didReceiveMemoryWarning()
    }
}

extension BaseTableViewController: LoginViewControllerDelegate {
    func loginDidSuccessful() {
        fetchDataDirectly()
    }
}
