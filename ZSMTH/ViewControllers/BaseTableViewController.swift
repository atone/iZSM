//
//  BaseTableViewController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/3/23.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController, LoginViewControllerDelegate {
    let api = SmthAPI()
    let setting = AppSetting.sharedSetting()

    var needRefresh = true

    // subclass need override this and add clear content
    func clearContent() {
        needRefresh = true
    }

    func fetchMoreData() {
        // fetch more data as user scroll up
    }

     func fetchDataDirectly() {
        // subclass must override this method to fetch initial data
        // without check login status
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // set tableview self-sizing cell
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

        // add observer to font size change
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(BaseTableViewController.preferredFontSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)

        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clearColor()
        tableView.tableFooterView = footerView

        tableView?.addLegendHeaderWithRefreshingTarget(self, refreshingAction: #selector(BaseTableViewController.checkLoginIfNeededOrFetchDataDirectly))
        tableView.header.updatedTimeHidden = true
    }

    // check login status and fetch initial data
    func fetchData() {
        tableView.header.beginRefreshing()
    }

    // check whether need login or just fetch data directly
    func checkLoginIfNeededOrFetchDataDirectly() {
        if let accessToken = setting.accessToken { // fetch data directly
            api.accessToken = accessToken
            fetchDataDirectly()
        } else if let username = setting.username, password = setting.password { // silent login
            networkActivityIndicatorStart()
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let loginSuccess = self.api.loginBBS(username: username, password: password) == 0 ? false : true
                dispatch_async(dispatch_get_main_queue()) {
                    networkActivityIndicatorStop()
                    if loginSuccess && self.api.errorCode == 0 {
                        self.setting.accessToken = self.api.accessToken
                        self.fetchDataDirectly()
                    } else {
                        self.tableView.header.endRefreshing()
                        self.api.displayErrorIfNeeded()
                    }
                }
            }

        } else { // present login view controller
            if let loginViewController = storyboard?.instantiateViewControllerWithIdentifier("LoginViewController") as? LoginViewController {
                loginViewController.delegate = self
                let rootvc = UIApplication.sharedApplication().keyWindow?.rootViewController
                rootvc?.presentViewController(loginViewController, animated: false, completion: nil)
            }
        }
    }

    func loginDidSuccessful() {
        fetchDataDirectly()
    }

    // remove observer of notification
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // solve the bug when swipe back, tableview cell doesn't deselect
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedRow, animated: true)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // refresh when needed
        if needRefresh {
            fetchData()
            needRefresh = false
        }
    }

    // handle font size change
    func preferredFontSizeChanged(notification: NSNotification) {
        tableView?.reloadData()
    }


}
