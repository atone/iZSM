//
//  NTTableViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2017/7/15.
//  Copyright © 2017年 Naitong Yu. All rights reserved.
//

import UIKit
import PullToRefreshKit

class NTTableViewController: UITableViewController {
    
    struct PullToRefreshKitConst {
        //KVO
        static let KPathOffSet = "contentOffset"
        static let KPathPanState = "state"
        static let KPathContentSize = "contentSize"
        
        //Default const
        static let defaultHeaderHeight:CGFloat = 50.0
        static let defaultFooterHeight:CGFloat = 44.0
        static let defaultLeftWidth:CGFloat    = 50.0
        static let defaultRightWidth:CGFloat   = 50.0
        
        //Tags
        static let headerTag = 100001
        static let footerTag = 100002
        static let leftTag   = 100003
        static let rightTag  = 100004
    }
    
    private let setting = AppSetting.shared
    
    var refreshHeader: DefaultRefreshHeader?
    var refreshFooter: DefaultRefreshFooter?
    
    var refreshHeaderEnabled: Bool = true {
        didSet {
            let headerContainer = self.view.viewWithTag(PullToRefreshKitConst.headerTag)
            if refreshHeaderEnabled {
                headerContainer?.isUserInteractionEnabled = true
                headerContainer?.isHidden = false
            } else {
                headerContainer?.isUserInteractionEnabled = false
                headerContainer?.isHidden = true
            }
        }
    }
    
    var refreshFooterEnabled: Bool = true {
        didSet {
            let footerContainer = self.view.viewWithTag(PullToRefreshKitConst.footerTag)
            if refreshFooterEnabled {
                footerContainer?.isUserInteractionEnabled = true
                footerContainer?.isHidden = false
            } else {
                footerContainer?.isUserInteractionEnabled = false
                footerContainer?.isHidden = true
            }
        }
    }
}
