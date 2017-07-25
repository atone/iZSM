//
//  NTTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/15.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit

class NTTableViewController: UITableViewController, SwipePopable {
    
    var swipePopGesture: UIPanGestureRecognizer?
    
    private let setting = AppSetting.shared

    override func viewDidLoad() {
        changeColor()
        // add observer to night mode change
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(nightModeChanged(_:)),
                                               name: AppTheme.kAppThemeChangedNotification,
                                               object: nil)
        super.viewDidLoad()
    }
    
    @objc private func nightModeChanged(_ notification: Notification) {
        changeColor()
    }
    
    func changeColor() {
        tableView.backgroundColor = (tableView.style == .grouped) ? AppTheme.shared.lightBackgroundColor : AppTheme.shared.backgroundColor
        tableView.tintColor = AppTheme.shared.tintColor
        
        tableView.mj_header?.backgroundColor = AppTheme.shared.backgroundColor
        (tableView.mj_header as? MJRefreshNormalHeader)?.activityIndicatorViewStyle = setting.nightMode ? UIActivityIndicatorViewStyle.white : UIActivityIndicatorViewStyle.gray
        (tableView.mj_header as? MJRefreshNormalHeader)?.stateLabel.textColor = AppTheme.shared.lightTextColor
        
        tableView.mj_footer?.backgroundColor = AppTheme.shared.backgroundColor
        (tableView.mj_footer as? MJRefreshAutoNormalFooter)?.activityIndicatorViewStyle = setting.nightMode ? UIActivityIndicatorViewStyle.white : UIActivityIndicatorViewStyle.gray
        (tableView.mj_footer as? MJRefreshAutoNormalFooter)?.stateLabel.textColor = AppTheme.shared.lightTextColor
        
        tableView.reloadData()
    }
}

protocol SwipePopable: class {
    var swipePopGesture: UIPanGestureRecognizer? { get set }
}
