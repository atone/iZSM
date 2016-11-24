//
//  SmthSplitViewController.swift
//  ZSMTH
//
//  Created by Naitong Yu on 15/3/15.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//

import UIKit

class SmthSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        var vc = secondaryViewController
        if let nvc = vc as? UINavigationController {
            vc = nvc.visibleViewController!
        }

        if let contentViewController = vc as? ArticleContentViewController where contentViewController.articleID == nil {
            return true
        }
        return false
    }

    func splitViewController(svc: UISplitViewController, shouldHideViewController vc: UIViewController, inOrientation orientation: UIInterfaceOrientation) -> Bool {
        return false
    }

}
