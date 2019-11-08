//
//  BaseTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2016/11/21.
//  Copyright © 2016年 Naitong Yu. All rights reserved.
//

import UIKit
import PullToRefreshKit

class BaseTableViewController: NTTableViewController {
    let api = SmthAPI.shared
    let setting = AppSetting.shared
    
    private var needRefresh = true
    static let kNeedRefreshNotification = Notification.Name("NeedRefreshContentNotification")
    
    var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }
    
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
        tableView.rowHeight = UITableView.automaticDimension
        
        // add observer to font size change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredFontSizeChanged(_:)),
                                               name: SettingsViewController.fontScaleDidChangeNotification,
                                               object: nil)
        // add observer to set need refresh
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(needRefreshNotificationDidPosted(_:)),
                                               name: BaseTableViewController.kNeedRefreshNotification,
                                               object: nil)
        
        // set extra cells hidden
        tableView.tableFooterView = UIView()
        let header = DefaultRefreshHeader.header()
        header.imageRenderingWithTintColor = true
        header.tintColor = UIColor.secondaryLabel
        tableView.configRefreshHeader(with: header, container: self) { [unowned self] in
            self.fetchData(showHUD: false, headerRefreshing: true)
        }
        
        super.viewDidLoad()
    }
    
    // check login status and fetch initial data
    func fetchData(showHUD: Bool, headerRefreshing: Bool = false) {
        isFocus = false
        let stopHeaderRefreshing: () -> Void = {
            if headerRefreshing {
                self.tableView.switchRefreshHeader(to: .normal(.none, 0))
            }
        }
        if !setting.eulaAgreed {
            let eulaViewController = EulaViewController()
            eulaViewController.delegate = self
            let navigationController = NTNavigationController(rootViewController: eulaViewController)
            navigationController.isModalInPresentation = true
            present(navigationController, animated: true)
        } else if setting.accessToken != nil { // fetch data directly
            fetchDataDirectly(showHUD: showHUD, completion: stopHeaderRefreshing)
        } else if let username = setting.username, let password = setting.password { // silent login
            networkActivityIndicatorStart()
            api.login(username: username, password: password) { (success) in
                DispatchQueue.main.async {
                    networkActivityIndicatorStop()
                    if success {
                        self.setting.accessToken = self.api.accessToken
                        self.fetchDataDirectly(showHUD: showHUD, completion: stopHeaderRefreshing)
                    } else {
                        stopHeaderRefreshing()
                    }
                }
            }
        } else { // present login view controller
            let loginViewController = LoginViewController()
            loginViewController.delegate = self
            let navigationController = NTNavigationController(rootViewController: loginViewController)
            navigationController.isModalInPresentation = true
            present(navigationController, animated: true)
        }
    }
    
    // remove observer of notification
    deinit {
        NotificationCenter.default.removeObserver(self)
        networkActivityIndicatorStop(withHUD: true)
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
    @objc private func preferredFontSizeChanged(_ notification: Notification) {
        tableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        if !isVisible {
            needRefresh = true
            clearContent()
            dPrint("Memory warning received, clear content on: \(self.description) title: \(self.title ?? "nil")")
        }
        super.didReceiveMemoryWarning()
    }
}

extension BaseTableViewController: LoginViewControllerDelegate {
    func loginDidSuccessful() {
        dPrint("login successful")
        dismiss(animated: true)
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

extension BaseTableViewController {
    var isFocus: Bool {
        get {
            return !clearsSelectionOnViewWillAppear
        }
        set {
            clearsSelectionOnViewWillAppear = !newValue
        }
    }
    
    func navigateDown() {
        isFocus = true
        var indexPath = IndexPath(row: 0, section: 0)
        if let ip = tableView.indexPathForSelectedRow {
            indexPath = ip
            if tableView.numberOfRows(inSection: indexPath.section) - 1 > indexPath.row {
                indexPath.row += 1
            } else if tableView.numberOfSections - 1 > indexPath.section {
                indexPath = IndexPath(row: 0, section: indexPath.section + 1)
            }
        } else if let ip = tableView.indexPathsForVisibleRows?.first {
            indexPath = ip
        } else {
            return
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        tableView.scrollToRow(at: indexPath, at: .none, animated: true)
    }
    
    func navigateUp() {
        isFocus = true
        var indexPath = IndexPath(row: 0, section: 0)
        if let ip = tableView.indexPathForSelectedRow {
            indexPath = ip
            if indexPath.row > 0 {
                indexPath.row -= 1
            } else if indexPath.section > 0 {
                let rowCount = tableView.numberOfRows(inSection: indexPath.section - 1)
                indexPath = IndexPath(row: rowCount - 1, section: indexPath.section - 1)
            }
        } else if let ip = tableView.indexPathsForVisibleRows?.last {
            indexPath = ip
        } else {
            return
        }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        tableView.scrollToRow(at: indexPath, at: .none, animated: true)
    }
    
    func navigateEnter() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
        }
    }
}
