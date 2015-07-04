//
//  NYNavigationController.swift
//  zsmth
//
//  Created by Naitong Yu on 15/7/3.
//  Copyright (c) 2015 Naitong Yu. All rights reserved.
//
//  This NavigationViewController should be used with RSTWebViewController,
//  it can auto hide the status bar and navigation bar when swipe.

import UIKit
import RSTWebViewController

class NYNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        hidesBarsOnSwipe = true
        barHideOnSwipeGestureRecognizer.addTarget(self, action: "swipe:")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    func swipe(gesture: UIPanGestureRecognizer) {
        let shouldHideStatusBar = navigationBar.frame.origin.y < 0

        if let webViewController = visibleViewController as? RSTWebViewController {
            webViewController.shouldHideStatusBar = shouldHideStatusBar
            UIView.animateWithDuration(0.2) { () -> Void in
                webViewController.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

}
