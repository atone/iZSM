//
//  BaseTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit

class BaseTableViewController: NTTableViewController {
    let api = SmthAPI()
    let setting = AppSetting.shared
    
    fileprivate var needRefresh = true
    static let kNeedRefreshNotification = Notification.Name("NeedRefreshContentNotification")
    
    // subclass need override this to actual clear content
    func clearContent() {
        fatalError("clearContent() NOT implemented")
    }
    
    @objc private func needRefreshNotificationDidPosted(_ notification: Notification) {
        needRefresh = true
        clearContent()
    }
    
    func fetchMoreData() {
        // fetch more data as user scroll up
        fatalError("fetchMoreData() NOT implemented")
    }
    
    func fetchDataDirectly(showHUD: Bool, completion: (() -> Void)? = nil) {
        // subclass must override this method to fetch initial data
        // without check login status
        fatalError("fetchDataDirectly(showHUD:completion:) NOT implemented")
    }
    
    override func viewDidLoad() {
        // set tableview self-sizing cell
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
        // add observer to set need refresh
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(needRefreshNotificationDidPosted(_:)),
                                               name: BaseTableViewController.kNeedRefreshNotification,
                                               object: nil)
        
        // set extra cells hidden
        let footerView = UIView()
        footerView.backgroundColor = UIColor.clear
        tableView.tableFooterView = footerView
        let header = MJRefreshNormalHeader(refreshingTarget: self,
                                           refreshingAction: #selector(fetchDataWithHeaderRefreshingAndNoHUD))
        header?.lastUpdatedTimeLabel.isHidden = true
        tableView.mj_header = header
        
        super.viewDidLoad()
    }
    
    @objc private func fetchDataWithHeaderRefreshingAndNoHUD() {
        fetchData(showHUD: false, headerRefreshing: true)
    }
    
    // check login status and fetch initial data
    func fetchData(showHUD: Bool, headerRefreshing: Bool = false) {
        if !setting.eulaAgreed {
            let eulaViewController = EulaViewController()
            eulaViewController.delegate = self
            let navigationController = NTNavigationController(rootViewController: eulaViewController)
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        } else if let accessToken = setting.accessToken { // fetch data directly
            api.accessToken = accessToken
            fetchDataDirectly(showHUD: showHUD) {
                if headerRefreshing {
                    self.tableView.mj_header.endRefreshing()
                }
            }
        } else if let username = setting.username, let password = setting.password { // silent login
            networkActivityIndicatorStart()
            DispatchQueue.global().async {
                let loginSuccess = self.api.loginBBS(username: username, password: password) == 0 ? false : true
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if loginSuccess && self.api.errorCode == 0 {
                        self.setting.accessToken = self.api.accessToken
                        self.fetchDataDirectly(showHUD: showHUD) {
                            if headerRefreshing {
                                self.tableView.mj_header.endRefreshing()
                            }
                        }
                    } else {
                        if headerRefreshing {
                            self.tableView.mj_header.endRefreshing()
                        }
                        self.api.displayErrorIfNeeded()
                    }
                }
            }
        } else { // present login view controller
            let loginViewController = LoginViewController()
            loginViewController.delegate = self
            let navigationController = NTNavigationController(rootViewController: loginViewController)
            present(navigationController, animated: false)
        }
    }
    
    // remove observer of notification
    // cancel unfinished tasks
    deinit {
        NotificationCenter.default.removeObserver(self)
        api.cancel()
        networkActivityIndicatorStop(withHUD: true)
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
            fetchData(showHUD: true)
            needRefresh = false
        }
    }
    
    // handle font size change
    func preferredFontSizeChanged(_ notification: Notification) {
        tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        needRefresh = true
        clearContent()
        super.didReceiveMemoryWarning()
    }
}

extension BaseTableViewController: LoginViewControllerDelegate {
    func loginDidSuccessful() {
        dPrint("login successful")
        dismiss(animated: false)
        fetchDataDirectly(showHUD: true)
    }
}

extension BaseTableViewController: EulaViewControllerDelegate {
    func userAcceptedEula(_ controller: EulaViewController) {
        // set agree to true
        setting.eulaAgreed = true
        dPrint("agree tapped")
        dismiss(animated: true)
        fetchData(showHUD: true)
    }
    
    func userDeclinedEula(_ controller: EulaViewController) {
        let alert = UIAlertController(title: nil, message: "您必须同意《水木社区管理规则》才能使用本软件。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        controller.present(alert, animated: true)
        dPrint("decline tapped")
    }
}

protocol SmthViewControllerPreviewingDelegate: class {
    func previewActionItems(for viewController: UIViewController) -> [UIPreviewActionItem]
}
