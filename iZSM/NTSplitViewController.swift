//
//  NTSplitViewController.swift
//  iZSM
//
//  Created by Naitong Yu on 2019/10/9.
//  Copyright © 2019 Naitong Yu. All rights reserved.
//

import UIKit

class NTSplitViewController: UISplitViewController {
    
    override var shouldAutorotate: Bool {
        return globalShouldRotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if globalLockPortrait {
            return [.portrait, .portraitUpsideDown]
        } else {
            return .all
        }
    }
    
    override var childForStatusBarHidden: UIViewController? {
        if isCollapsed {
            return viewControllers.first
        } else {
            return viewControllers.last
        }
    }
}

